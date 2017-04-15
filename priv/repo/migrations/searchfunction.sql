begin;

alter table people add column tsearch tsvector;
create or replace function people_update_tsearch() returns trigger as $$
begin
   new.tsearch :=  setweight(to_tsvector('german', coalesce(new.lastname,'')), 'A') ||
                  setweight(to_tsvector('german', coalesce(new.firstname,'')), 'B') ||
                  setweight(to_tsvector('german', coalesce(new.comment,'')), 'C') ||
						      setweight(to_tsvector('german', 
		         			  coalesce((select string_agg(comment, ' ') from places_people where person_id=new.id),'')), 'B');

   return new;
end;
$$ language plpgsql;
create trigger people_update_tsearch before insert or update on people 
       for each row execute procedure people_update_tsearch();


create or replace function del_places_people_update_tsearch() returns trigger as $$
begin
    update people set id=id where id=old.person_id;
		return old;
end;
$$ language plpgsql;

create or replace function places_people_update_tsearch() returns trigger as $$
begin
    update people set id=id where id=new.person_id;
		return new;
end;
$$ language plpgsql;


create trigger people_places_update_tsearch after insert or update on places_people
       for each row execute procedure places_people_update_tsearch();

create trigger people_places_update_tsearch after delete on places_people
       for each row execute procedure del_people_places_update_tsearch();


-- places_items

create or replace function del_places_items_update_tsearch() returns trigger as $$
begin
    update items set id=id where id=old.item_id;
		return old;
end;
$$ language plpgsql;

create or replace function places_items_update_tsearch() returns trigger as $$
begin
    update items set id=id where id=new.item_id;
		return new;
end;
$$ language plpgsql;


create trigger people_places_update_tsearch after insert or update on places_items
       for each row execute procedure places_items_update_tsearch();

create trigger people_places_update_tsearch after delete on places_items
       for each row execute procedure del_places_items_update_tsearch();



-- places

alter table places add column tsearch tsvector;
create function places_update_tsearch() returns trigger as $$
begin
   new.tsearch :=  setweight(to_tsvector('german', coalesce(new.city,'')), 'A') ||
                  setweight(to_tsvector('german', coalesce(new.address,'')), 'A') ||
                  setweight(to_tsvector('german', coalesce(new.comment,'')), 'B');
   return new;
end;
$$ language plpgsql;
create trigger places_update_tsearch before insert or update on places
       for each row execute procedure places_update_tsearch();

-- end places



alter table keywords add column tsearch tsvector;
create function keywords_update_tsearch() returns trigger as $$
begin
   new.tsearch :=  setweight(to_tsvector('german', coalesce(new.category,'')), 'A') ||
                  setweight(to_tsvector('german', coalesce(new.name,'')), 'A') ||
                  setweight(to_tsvector('german', coalesce(new.comment,'')), 'C');
   return new;
end;
$$ language plpgsql;
create trigger keywords_update_tsearch before insert or update on keywords 
       for each row execute procedure keywords_update_tsearch();


alter table images add column tsearch tsvector;
create or replace function images_update_tsearch() returns trigger as $$
begin
       new.tsearch :=  setweight(to_tsvector('german', coalesce(new.comment,'')), 'A') ||
                      setweight(to_tsvector('german', coalesce(new.original_filename,'')), 'B') ||
		      setweight(to_tsvector('german', 
		         coalesce((select string_agg(comment, ' ') from imagetags where image_id=new.id),'')), 'B');
		   return new;
end;
$$ language plpgsql;
create trigger images_update_tsearch before insert or update on images 
       for each row execute procedure images_update_tsearch();
--  this is just to trigger the update on images.tsearch

create or replace function imagetags_update_tsearch() returns trigger as $$
begin
    update images set id=id where id=new.image_id;
		return new;
end;
$$ language plpgsql;
create trigger imagetags_update_tsearch before insert or update on imagetags 
       for each row execute procedure imagetags_update_tsearch();
alter table items add column tsearch tsvector;
create or replace function items_update_tsearch() returns trigger as $$
begin
       new.tsearch :=  setweight(to_tsvector('german', coalesce(new.name,'')), 'A') ||
                      setweight(to_tsvector('german', coalesce(new.comment,'')), 'B') ||
											setweight(to_tsvector('german', coalesce(new.inventory,'')), 'A') ||
											setweight(to_tsvector('german', coalesce(new.filenr,'')), 'A') ||
											setweight(to_tsvector('german', coalesce(new.filecomment,'')), 'C') ||
  							      setweight(to_tsvector('german', 
		         			  coalesce((select string_agg(comment, ' ') from places_items where item_id=new.id),'')), 'B');
 				return new;							
end;
$$ language plpgsql;

create trigger items_update_tsearch before insert or update on items
     for each row execute procedure items_update_tsearch();


create or replace function search_all(text, int)
			 returns table(what varchar, id int, name text, comment text, image_id int) as $$
with query as (select to_tsquery($1) as query)
(select 'person'::varchar, 
       p.id, 
       concat_ws(' ', p.firstname, p.lastname), 
       p.comment || ' ' || coalesce((select string_agg(k.category || ': ' || k.name, ' / ') from 
                            keywords k, people_keywords pk where pk.person_id=p.id and 
                            pk.keyword_id=k.id), ''),
       (select image_id from imagetags where person_id=p.id order by is_primary desc limit 1)
from people p, query  q where q.query @@ p.tsearch
     order by ts_rank_cd(p.tsearch, q.query) desc limit $2)

union all

(select 'item'::varchar, 
       i.id,
       i.name,
       concat(i.comment, ' ', (select string_agg(k.category || ': ' || k.name, ' / ') from 
                            keywords k, item_keywords ik where ik.item_id=i.id and 
                            ik.keyword_id=k.id)),
       (select image_id from imagetags where item_id=i.id order by is_primary desc limit 1)
from items i, query  q where q.query @@ i.tsearch
     order by ts_rank_cd(i.tsearch, q.query) desc limit $2)

union all

(select 'image'::varchar, 
       i.id,
			 i.original_filename,
			 concat(i.comment, ' ', (select string_agg(p.firstname || ' ' || p.lastname, ', ') 
                            from imagetags it, people p where it.image_id=i.id and it.person_id=p.id),
							' ', (select string_agg(items.name, ', ') 
                            from imagetags it, items where items.id=it.item_id and it.image_id=i.id)),
       i.id
from images i, query  q where q.query @@ i.tsearch
     order by ts_rank_cd(i.tsearch, q.query) desc limit $2)

union all

(select 'keyword'::varchar, 
       k.id,
			 k.category || ': ' || k.name,
       concat(k.comment, ' ', 'Person: ', 
			           (select count(*) from people_keywords where keyword_id=k.id), ', ', 
			 					 (select string_agg(s, ', ') from
								   (select it.name || ': ' ||  count(*) as s from
									    item_keywords ik, items i, itemtypes it where ik.item_id=i.id and
											i.itemtype_id=it.id and ik.keyword_id=k.id group by it.name) strings)),
			coalesce((select it.image_id from imagetags it, people_keywords pk where pk.keyword_id=k.id and
						 					pk.person_id=it.person_id order by is_primary desc limit 1),
											(select it.image_id from imagetags it, item_keywords ik where ik.keyword_id=k.id and
						 					ik.item_id=it.item_id order by is_primary desc limit 1))
from keywords k, query  q where q.query @@ k.tsearch
     order by ts_rank_cd(k.tsearch, q.query) desc limit $2)
union all


(select 'place'::varchar, 
       p.id,
			 concat_ws(' ', p.city, p.address),
			 p.comment,
			 (select image_id from imagetags where place_id=p.id order by is_primary desc limit 1)
from places p, query  q where q.query @@ p.tsearch
     order by ts_rank_cd(p.tsearch, q.query) desc limit $2)

$$ language sql;

create index people_tsearch on people using gist(tsearch);
create index items_tsearch on items using gist(tsearch);
create index keywords_tsearch on keywords using gist(tsearch);
create index images_tsearch on images using gist(tsearch);

create index places_tsearch on places using gist(tsearch);

-- 
-- 
-- -- down 
-- alter table people drop column tsearch;
-- alter table items drop column tsearch;
-- alter table images drop column tsearch;
-- create function people_update_tsearch();
-- create function images_update_tsearch();
-- create function imagetags_update_tsearch();
-- create function items_update_tsearch();
-- drop function search_all(text);


 commit;
