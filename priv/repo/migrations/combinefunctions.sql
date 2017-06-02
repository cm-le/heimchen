create or replace function merge_people(p1 int, p2 int) returns boolean as $$
begin
  delete from people_keywords pk1 where person_id=p2 and
  	 0<(select count(*) from people_keywords pk2 where pk2.person_id=p1 and
	    pk2.keyword_id=pk1.keyword_id);
  update people_keywords set person_id=p1 where person_id=p2;

  delete from imagetags it1 where person_id=p2 and
  	 0<(select count(*) from imagetags it2 where it2.person_id=p1 and
	    it2.image_id=it1.image_id);
  update imagetags set person_id=p1 where person_id=p2;

  delete from places_people pp1 where person_id=p2 and
  	 0<(select count(*) from places_people pp2 where pp2.person_id=p1 and
	    pp2.place_id=pp1.place_id);
  update places_people set person_id=p1 where person_id=p2;

  update items set received_by_id=p1 where received_by_id=p2;
  update people set
     firstname=coalesce(nullif(firstname, ''),
                        (select firstname from people where id=p2)),
     lastname =coalesce(nullif(lastname, ''),
                        (select lastname from people where id=p2)),
     maidenname =coalesce(nullif(maidenname, ''),
                        (select maidenname from people where id=p2)),
     comment =coalesce(nullif(comment, ''),
                        (select comment from people where id=p2)),
     gender   =coalesce(gender,
                        (select gender from people where id=p2)),
     born_on   =coalesce(born_on,
                        (select born_on from people where id=p2)),
     born_precision   =coalesce(born_precision,
                        (select born_precision from people where id=p2)),
     died_on   =coalesce(died_on,
                        (select died_on from people where id=p2)),
     died_precision   =coalesce(died_precision,
                        (select died_precision from people where id=p2))
     where id=p1;
     delete from people where id=p2;
     return true;
end;
$$ language plpgsql;



---


create or replace function merge_places(p1 int, p2 int) returns boolean as $$
begin
  delete from imagetags it1 where place_id=p2 and
  	 0<(select count(*) from imagetags it2 where it2.place_id=p1 and
	    it2.image_id=it1.image_id);

  update imagetags set place_id=p1 where place_id=p2;


  delete from places_keywords pk1 where place_id=p2 and
  	 0<(select count(*) from places_keywords pk2 where pk2.place_id=p1 and
	    pk2.keyword_id=pk1.keyword_id);
  update places_keywords set place_id=p1 where place_id=p2;

  delete from places_items pi1 where place_id=p2 and
  	 0<(select count(*) from places_items pi2 where pi2.place_id=p1 and
	    pi2.item_id=pi1.item_id);
  update places_items set place_id=p1 where place_id=p2;


  delete from places_people pp1 where place_id=p2 and
  	 0<(select count(*) from places_people pp2 where pp2.place_id=p1 and
	    pp2.person_id=pp1.person_id);
  update places_people set place_id=p1 where place_id=p2;
  
  update places set
     building=coalesce(nullif(building, ''),
                        (select building from places where id=p2)),
     comment=coalesce(nullif(comment, ''),
                        (select comment from places where id=p2)),
     lat=coalesce(lat,
                  (select lat from places where id=p2)),
     long=coalesce(long,
                  (select long from places where id=p2))
     where id=p1;

    delete from places where id=p2;
    return true;
end;
$$ language plpgsql;



create or replace function merge_items(i1 int, i2 int) returns boolean as $$
begin
  delete from imagetags it1 where item_id=i2 and
  	 0<(select count(*) from imagetags it2 where it2.item_id=i1 and
	    it2.image_id=it1.image_id);

  update imagetags set item_id=i1 where item_id=i2;


  delete from item_keywords ik1 where item_id=i2 and
  	 0<(select count(*) from item_keywords ik2 where ik2.item_id=i1 and
	    ik2.keyword_id=ik1.keyword_id);
  update item_keywords set item_id=i1 where item_id=i2;


  update items set
     comment=coalesce(nullif(comment, ''),
                        (select comment from items where id=i2)),
     received_by_id=coalesce(received_by_id,
                        (select received_by_id from items where id=i2)),
     received_comment=coalesce(nullif(received_comment, ''),
                        (select received_comment from items where id=i2)),
     date_on=coalesce(date_on,
                        (select date_on from items where id=i2)),
     date_precision=coalesce(date_precision,
                        (select date_precision from items where id=i2))
			
     where id=i1;
    delete from items where id=i2;
    return true;
end;
$$ language plpgsql;
