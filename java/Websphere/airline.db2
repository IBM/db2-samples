db2start;
create db airline;

connect to airline;


create table reservation_table (flight_id varchar(10) NOT NULL PRIMARY KEY, airlines varchar(20), departure time, arrival time, duration time, fare_type varchar(20), fare varchar(10), seats_available integer, source varchar(10), destination varchar(10), date date);

create table passenger_details (firstname varchar(20), lastname varchar(20),emailid varchar(30), phoneno varchar(20), userid varchar(20),passwd varchar(20), address varchar(60), alt_emailid varchar(30), BIRTHDATE date, sex varchar(6), pincode varchar(10));

create table new_flights(FLIGHT_ID VARCHAR(10),AIRLINE VARCHAR(20),DEPARTURE TIME,ARRIVAL TIME,DURATION TIME,FARE_TYPE VARCHAR(20),FARE VARCHAR(10),SEATS INTEGER,SOURCE VARCHAR(10),DESTINATION VARCHAR(10),DATE DATE);


insert into reservation_table values('E1','Emirates','11:30:00','05:30:00','06:00:00','Refundable','$580',130,'Bangalore','Toronto',current date + 10 DAYS);
insert into reservation_table values('E2','Emirates','11:30:00','05:30:00','06:00:00','Refundable','$650',120,'Bangalore','London',current date + 10 DAYS);
insert into reservation_table values('AI1','AirIndia','10:00:00','20:00:00','10:00:00','Refundable','$1200',100,'Bangalore','Newyork',current date + 10 DAYS);
insert into reservation_table values('AI2','AirIndia','10:00:00','20:00:00','10:00:00','Refundable','$1200',100,'Bangalore','Delhi',current date + 10 DAYS);

insert into reservation_table values('E3','Emirates','11:30:00','05:30:00','06:00:00','Refundable','$580',130,'Bangalore','Toronto',current date + 8 DAYS);
insert into reservation_table values('E4','Emirates','11:30:00','05:30:00','06:00:00','Refundable','$650',120,'Bangalore','London',current date + 8 DAYS);
insert into reservation_table values('AI4','AirIndia','10:00:00','20:00:00','10:00:00','Refundable','$1200',100,'Bangalore','Newyork',current date + 8 DAYS);
insert into reservation_table values('AI3','AirIndia','10:00:00','20:00:00','10:00:00','Refundable','$1200',100,'Bangalore','Delhi',current date + 8 DAYS);

insert into reservation_table values('E5','Emirates','11:30:00','05:30:00','06:00:00','Refundable','$550',100,'London','Toronto',current date + 10 DAYS);
insert into reservation_table values('AI6','AirIndia','11:30:00','05:30:00','06:00:00','Refundable','$550',100,'London','Newyork',current date + 10 DAYS);
insert into reservation_table values('KF10','KingFisher','11:30:00','05:30:00','06:00:00','Refundable','$550',100,'London','Bangalore',current date + 10 DAYS);
insert into reservation_table values('KF9','KingFisher','11:30:00','05:30:00','06:00:00','Refundable','$550',100,'London','Delhi',current date + 10 DAYS);

insert into reservation_table values('E6','Emirates','11:30:00','05:30:00','06:00:00','Refundable','$550',100,'London','Toronto',current date + 8 DAYS);
insert into reservation_table values('AI7','AirIndia','11:30:00','05:30:00','06:00:00','Refundable','$550',100,'London','Newyork',current date + 8 DAYS);
insert into reservation_table values('KF8','KingFisher','11:30:00','05:30:00','06:00:00','Refundable','$550',100,'London','Bangalore',current date + 8 DAYS);
insert into reservation_table values('KF7','KingFisher','11:30:00','05:30:00','06:00:00','Refundable','$550',100,'London','Delhi',current date + 8 DAYS);

insert into reservation_table values('L1','Lufthansa','11:00:00','17:00:00','06:00:00','Non-Refundable','$600',100,'Newyork','Toronto',current date + 10 DAYS);
insert into reservation_table values('KF1','KingFisher','11:00:00','17:00:00','06:00:00','Non-Refundable','$600',100,'Newyork','London',current date + 10 DAYS);
insert into reservation_table values('AI8','AirIndia','11:00:00','17:00:00','06:00:00','Non-Refundable','$600',100,'Newyork','Bangalore',current date + 10 DAYS);
insert into reservation_table values('AI9','AirIndia','11:00:00','17:00:00','06:00:00','Non-Refundable','$600',100,'Newyork','Delhi',current date + 10 DAYS);


insert into reservation_table values('L2','Lufthansa','11:00:00','17:00:00','06:00:00','Non-Refundable','$600',100,'Newyork','Toronto',current date + 8 DAYS);
insert into reservation_table values('KF2','KingFisher','11:00:00','17:00:00','06:00:00','Non-Refundable','$600',100,'Newyork','London',current date + 8 DAYS);
insert into reservation_table values('AI10','AirIndia','11:00:00','17:00:00','06:00:00','Non-Refundable','$600',100,'Newyork','Bangalore',current date + 8 DAYS);
insert into reservation_table values('AI11','AirIndia','11:00:00','17:00:00','06:00:00','Non-Refundable','$600',100,'Newyork','Delhi',current date + 8 DAYS);

insert into reservation_table values('KF3','KingFisher','09:00:00','17:00:00','08:00:00','Refundable','$1000',100,'Delhi','London',current date + 8 DAYS);
insert into reservation_table values('L3','Lufthansa','09:00:00','17:00:00','08:00:00','Refundable','$1000',100,'Delhi','Toronto',current date + 8 DAYS);
insert into reservation_table values('KF4','KingFisher','09:00:00','17:00:00','08:00:00','Refundable','$1000',100,'Delhi','Newyork',current date + 8 DAYS);
insert into reservation_table values('AI12','AirIndia','09:00:00','17:00:00','08:00:00','Refundable','$1000',100,'Delhi','Bangalore',current date + 8 DAYS);

insert into reservation_table values('KF5','KingFisher','09:00:00','17:00:00','08:00:00','Refundable','$1000',100,'Delhi','London',current date + 10 DAYS);
insert into reservation_table values('L4','Lufthansa','09:00:00','17:00:00','08:00:00','Refundable','$1000',100,'Delhi','Toronto',current date + 10 DAYS);
insert into reservation_table values('KF6','KingFisher','09:00:00','17:00:00','08:00:00','Refundable','$1000',100,'Delhi','Newyork',current date + 10 DAYS);
insert into reservation_table values('AI13','AirIndia','09:00:00','17:00:00','08:00:00','Refundable','$1000',100,'Delhi','Bangalore',current date + 10 DAYS);

insert into passenger_details values('joe','smith','joe_smith@in.ibm.com','9876545674','joesmi','commit','toronto','sm_joe@in.ibm.com','1980-10-7','male','456789');


db2stop force;
db2start;

connect to airline;

update db cfg using cur_commit ON;
update db cfg using LOCKTIMEOUT 01;

db2stop force;
db2start;
connect to airline;