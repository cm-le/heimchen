create table data.researchdatasets(
       id serial primary key,
			 sid varchar,
			 name varchar,
			 comment text
);
alter table data.researchdatasets owner to datamanager;

create table data.participants_researchdatasets(
			 id serial,
			 participant_id integer not null references data.participants(id),
			 researchdataset_id integer not null references data.researchdatasets(id),
			 inserted_at timestamp not null default current_timestamp
);
			 
alter table data.participants_researchdatasets owner to datamanager;


create view research.participants as
			 select p.vic as sic,
			 1 as metadata_visit_round,
			 rd.sid as metadata_research_dataset
			 from data.participants p, data.researchdatasets rd,
			 data.participants_researchdatasets pr where
			 pr.participant_id=p.id and pr.researchdataset_id=rd.id;
alter view research.participants  owner to datamanager;
