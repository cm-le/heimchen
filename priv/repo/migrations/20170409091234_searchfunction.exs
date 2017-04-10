defmodule Heimchen.Repo.Migrations.Searchfunction do
  use Ecto.Migration

  def up do

     execute """
-- FIXME create indixes

alter table people add column tsearch tsvector;
create function people_update_tsearch() returns trigger as $$
begin
   new.tsearch =  setweight(to_tsvector('german', coalesce(new.lastname,'')), 'A') ||
                  setweight(to_tsvector('german', coalesce(new.firstname,'')), 'B') ||
                  setweight(to_tsvector('german', coalesce(new.comment,'')), 'C');
   return new;
end;
$$ language plpgsql;
create trigger people_update_tsearch before insert or update on people 
       for each row execute procedure people_update_tsearch();

alter table images add column tsearch tsvector;
create function images_update_tsearch() returns trigger as $$
       new.tsearch =  setweight(to_tsvector('german', coalesce(new.comment,'')), 'A') ||
                      setweight(to_tsvector('german', coalesce(new.original_filename,'')), 'B') ||
		      setweight(to_tsvector('german', 
		         coalesce((select string_agg(comment, ' ') from imagetags where image_id=new.id),'')), 'B');
end;
$$ language plpgsql;
create trigger images_update_tsearch before insert or update on images 
       for each row execute procedure images_update_tsearch();


-- this is just to trigger the update on images.tsearch
create function imagetags_update_tsearch() returns trigger as $$
begin
    update images set id=id;
end;
$$ language plpgsql;
create trigger imagetags_update_tsearch before insert or update on images 
       for each row execute procedure imagetags_update_tsearch();


alter table items add column tsearch tsvector;
create function items_update_tsearch() returns trigger as $$
       new.tsearch =  setweight(to_tsvector('german', coalesce(new.name,'')), 'A') ||
                      setweight(to_tsvector('german', coalesce(new.comment,'')), 'B');
end;
$$ language plpgsql;
create trigger items_update_tsearch before insert or update on items
       for each row execute procedure items_update_tsearch();

create function search_all(text) returns table(what varchar, id int, name text, comment text, image_id int) as $$
with query as (select to_tsquery($1) as query)
select 'person'::varchar, 
       p.id, 
       concat_ws(' ', p.firstname, p.lastname), 
       p.comment || ' ' || (select string_agg(k.category || ': ' || k.name, ' / ') from 
                            keywords k, people_keywords pk where pk.person_id=p.id and 
                            pk.keyword_id=k.id),
       (select image_id from imagetags where person_id=p.id order by is_primary desc limit 1)
from people p, query  q where q.query @@ p.tsearch
     order by ts_rank_cd(p.tsearch, q.query) desc limit 10

union all

select 'item'::varchar, 
       i.id,
       i.name,
       i.comment || ' ' || (select string_agg(k.category || ': ' || k.name, ' / ') from 
                            keywords k, item_keywords ik where ik.item_id=i.id and 
                            ik.keyword_id=k.id),
       (select image_id from imagetags where item_id=i.id order by is_primary desc limit 1)
from items i, query  q where q.query @@ i.tsearch
     order by ts_rank_cd(p.tsearch, q.query) desc limit 10

union all

select 'image'::varchar, 
       i.id,
       i.name,
       i.comment || ' ' || (select string_agg(p.firstname || ' ' || p.lastname, ', ') 
                            from imagetags it, people p where it.image_id=i.id and it.person_id=p.id) ||
                 ' ' || (select string_agg(items.name, ', ') 
                            from imagetags it, items where items.it=it.item_id and it.image_id=i.id),
       i.id
from images i, query  q where q.query @@ i.tsearch
     order by ts_rank_cd(p.tsearch, q.query) desc limit 10

$$ language sql;

"""
  end


  def down do
     execute """"
alter table people drop column tsearch;
alter table items drop column tsearch;
alter table images drop column tsearch;
create function people_update_tsearch();
create function images_update_tsearch();
create function imagetags_update_tsearch();
create function items_update_tsearch();
drop function search_all(text);

"""
  end

end
