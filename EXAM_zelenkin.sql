---�������� ������ �SQL � ��������� �������

--task_1 � ����� ������� ������ ������ ���������?

/*� ���� ������� � ����� �� ������� airports ��� ������, � ������� ���� ���������,
 * � ����� ���������� ���������� � ������, ������������ �� �� �������� city.
 * ��� ���������� ����� � �����.�������� count �� ��������� ������� � ����������� �������� having. */

select city, count(airport_name) as quantity
from airports
group by 1
having count(airport_name)>1

----------------------------------------------------------------------------------------
--task_2 � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?

/*� ���� ������� � ������� ���������, � ������� ����� �� ������� aircrafts ������ � ������������ ������������� �������,
 * ��������� �������������� �� �������� � ��������, � ��������� ��������� ���������� ������ ���������
 * � ������� ��������� limit.
 * ����� ��������� � ����������� � �������, �������� ��� ����������� �� ���������� ������ �� ������� flights */

select distinct(f.departure_airport)as airport, t.aircraft_code as aircraft
from(
	select aircraft_code ,range 
	from aircrafts a 
	order by range desc
	limit 1)t
join flights f on f.aircraft_code=t.aircraft_code

----------------------------------------------------------------------------------------
--task_3 ������� 10 ������ � ������������ �������� �������� ������

/*� ���� �������, ��������� ������� flights, � ����� � ������, �� ID, � ����� �������� ����� �������� �������� �����������
 * � ��������, ��������������� �� ����������. � ����� ������� where, ��� ������ �� ��������� ������� ����������� �� �������� NULL.
 * ���������� �������� �������� �� �������� � ��������, � ��������� ���������� ������� 10 � ������� ��������� limit.*/

select flight_no,flight_id ,actual_departure-scheduled_departure as dep_delay
from flights f 
where actual_departure is not null
order by dep_delay desc
limit 10 

----------------------------------------------------------------------------------------
--task_4 ���� �� �����, �� ������� �� ���� �������� ���������� ������?

/*� ���� ������� � ����� ���������� ������ ������������ �� ������� bookings, 
 * � ������� left join �������� ���������� ������ ����������� � ������� ���������� �������
 * �� ������� boarding_passes �� � �������(����� join ������� tickets �� � ������������) ,
 * ������� ��� �� ����� �� ������� where, ��� �������� boarding_no �������� NULL.*/

select distinct(b.book_ref) ,bp.boarding_no
from bookings b 
join tickets t on t.book_ref =b.book_ref 
left join boarding_passes bp on bp.ticket_no =t.ticket_no 
where bp.boarding_no is null

----------------------------------------------------------------------------------------
--task_5 ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� 
--���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
--(�.�. � ���� ������� ������ ���������� ������������� ����� - ������� 
--������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.)


/*� ���� ������� � �����������: 
 * ��������� bp, � ������� � ����� �� ������� boarding_passes ID �������� � ���������� ������� �� ������ �� ��� ����,
 *  ������������ � ���������� �� �� ID ��������;
 * ��������� s, � ������� � ����� �� ������� seats ���� �������� � ���������� ��������� �� ����� ����,
 *  ������������ �� �� ���� �������.
 * ������� flights � �������� �����������, ����������� ��� ���������� ("bp"-�� ����� ID ��������, � "s"-�� ����� ��������).
 * �����, � �������� �������, � ����� ID �������, ��� �������, ��� ���������, ���� ������,
 *  ���������� ��������� ����, ��� �������� ���������� ���� ��������� �� ����� ���� � ���������� ������� ����,
 *  ������� ��������� ���� �� ���� ��������� � ������ ������� � ������� ��������� round � ���������� ������ � ������ numeric.
 * ��� ������ ������� ������� ����� ������������� ����� ���������� ���������� ���������� �� ������� ��������� �� ������ ����,
 *  � ����� ����� ���������� ����������, �������� �� ������ �����.
 * � ������� ��������� where � ����� �������, �� ������� ������� � ����������� �� ����� ������ � ������� �� ����� ������
 *  ������ ��������� "NOT NULL-��������", � ���������� ������ �� ���� ������.
 */	
	
select f.flight_id, 
	f.aircraft_code, 
	f.departure_airport, 
	f.actual_departure::date,
	(s.all_seats - bp.reser_seats) as free_seats,
	round(((s.all_seats - bp.reser_seats)::numeric * 100 / s.all_seats::numeric), 1) as free_percent,
	sum(bp.reser_seats) over (partition by f.actual_departure::date, f.departure_airport order by f.actual_departure) as passenger_sum,
	bp.reser_seats as passengers_on_flight
from flights f
left join (
	select flight_id, 
	count(seat_no) as reser_seats
	from boarding_passes bp
	group by flight_id
	order by flight_id) as bp on bp.flight_id = f.flight_id 
left join (
	select aircraft_code, 
	count(seat_no) as all_seats
	from seats s 
	group by aircraft_code) as s on f.aircraft_code = s.aircraft_code
where f.actual_departure is not null and bp.reser_seats is not null
order by f.actual_departure::date

----------------------------------------------------------------------------------------
--task_6 ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
	
/*� ���� ������� � ����������� ��������� t, � ������� ����� �� ������� �������� flights ���� ��������, ����������� �������.
 *��������� ������� �������,� ��������� ���������� ���� �������� � ������ ���� �������, 
 * ��������� ���� �� ���� ������� � ������� partition by; ����� ���� ��������� � ������� �� ��������� ������� �������,
 * ��������� ����� ���������� ���� ����������� ��������, ����� ���������� �������� ��������� ������ � ������ numeric.
 *����� � ������� ��������� ������� �� 100, � � ������� ��������� round ������� � ����� ���������� �������� �������� �� ������ ��� �������.
 *
 *� �������� ������� � ����� �� ����������� ���������� t ���������� ���� ��������, � ����� ���������� �����������
 * �������� ��� ������� ���� ��������� �� ������ ���������� ��������.*/

select 
	distinct aircraft_code,percent
from(
	select
		aircraft_code,
		round(count(flight_id)over(partition by aircraft_code)::numeric/count(flight_id)over()::numeric*100,1)as percent
	from flights)t
	
----------------------------------------------------------------------------------------
--task_7 ���� �� ������, � ������� ����� ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
	
/*� ���� ������� � ����������� ���, � ������� �����:
 * ID ��������, ����� ����� ��������� � ��������� ������� ������� �� ������� ticket_flights,
 *  � ����� ��� � ����� ��������� ������ �� ������� airports ���� ����������,
 *  ��������� ������� ticket_flights � �������� flights �� ID ��������, � ����� � �������� airports �� ����� ����� ����������.
 * 	���������� ������ ���������� �� flight_id, fare_conditions � amount.
 * 
 * �����, ��������� ���, � ����� �������� ������ �������, ��������������� �� ������� � ID ��������,
 *  � � ������� ��������� having ������� ���������� �����������,
 *  �� ������� ���������� case � ����� �������, ��� ������� ���������� �������� ��������� ������� ������-������� 
 *  ������ ���� ������ ����������� �������� ��������� ������� ������-������� � �������� ������.*/

with cte as(
	select tf.flight_id,tf.fare_conditions,tf.amount,a.airport_code, a.city
	from ticket_flights tf 
	join flights f on tf.flight_id =f.flight_id 
	join airports a on f.arrival_airport =a.airport_code 
	order by 1,2,3)
select city
from cte
group by city,flight_id
having max(case 
			when fare_conditions='Economy' 
			then amount 
			else null 
			end) >
		min(case 
			when fare_conditions='Business' 
			then amount 
			else null 
			end)

----------------------------------------------------------------------------------------
--task_8 ����� ������ �������� ��� ������ ������?

/*� ���� ������� � ������ 2 �������������:
 * � ������������� all_variants � ����� ��� ��������� ��������� �������, � ������� ���� ���������  �� ������� airports,
 *  ��������� ��������� ������������ � ����������� from. ��� ����, ����� �� ���� ���������� ���������, � ����� ������� ����� �������� where � ���������� <.
 * � ������������� known_flights � ����� ��������� �������� ������� ������ � ������� ������, ��������� ��� �������� �� ������� flights,
 *  �������� � ������� �� ������� airports; ������� �� ��������� ����� ���������� ������ � ������ �� airports,
 *  ����� �� ��������� ����� ���������� ������ � ������ �� airports.
 * ����� � ����� ����� ������� ����� �������� where � ���������� <, �� �������� ����������� ���������� ����������.
 * 
 * �����, ��������� �������� except, � ����� ��� �������� ��������� �������, �������� ���������� ������� �� ������������� known_flights,
 *  ��� ����� ��������� ������ ��������� �������, ������� �� ����� ����� ����� ��������� ��� ������ ������.
 * ��� �������� ���������� ��������� ������� � ���������� � ���������� �������.*/

create view all_variants as
select q.city as city_A, w.city as city_B
from airports q, airports w
where q.city < w.city

create view known_flights as
select distinct a1.city as city_A,a2.city as city_B
from flights f
join airports a1 on f.departure_airport =a1.airport_code
join airports a2 on f.arrival_airport =a2.airport_code
where a1.city <a2.city

select * from all_variants
except
select * from known_flights
order by 1,2


----------------------------------------------------------------------------------------
--task_9 ��������� ���������� ����� �����������, ���������� ������� �������, 
--�������� � ���������� ������������ ���������� ���������  � ���������, 
--������������� ��� �����

/*� ���� ������� � ����������� ��������� t, � ������� ����� �� ������� flights � �������, ��� �������, ������������ ������ ������,
 * �� ���������� ��������� �������� �� ���� ���������� �������� aircrafts �� ���� �������,
 * �������� ������ � ������, � ����� ���������� � ������� ��������� radians � ������� �������� ������ � ������� ������� �� ���� ����������
 * �� ���� ���������� ������� �� ������� airports,�������� � ������� �� ���� ��������� ������, ����� ��� ��� �� ���� ��������� ������.
 *������ � ���������� �� � �������.
 * 
 *�����, �� ���������� t � ����� � �������, ������� ������� (��������� �������� concat � ��������� ���� ��������� � ���� �������-�������),
 * � ������� ��������� acos � ��������� ���������� � ���������� ����� ����������� �� �������� �� �������:
 * acos(sin(latitude_a)*sin(latitude_b) + cos(latitude_a)*cos(latitude_b)*cos(longitude_a - longitude_b))*6371.
 *�����, � ������� ��������� case, � �������� �������, �� �������� ��� ��������� ���������� ��������� ������� � ����������� ����� ����������� � ������,
 * ���� ���������� ������ ���������� ���������, �� ������ ������ �������� "�������", � � ���� ������-"�� �������".*/

select t.flight_no,
	concat(airport_a,'-',airport_b) as route,
	acos(sin(latitude_a)*sin(latitude_b) + cos(latitude_a)*cos(latitude_b)*cos(longitude_a - longitude_b))*6371 as distance,
	case
		when acos(sin(latitude_a)*sin(latitude_b) + cos(latitude_a)*cos(latitude_b)*cos(longitude_a - longitude_b))*6371<"range"
		then 'Arrived'
		else 'Not_arrived'
	end as arrived_or_not
from(
		select distinct f.flight_no,
				f.departure_airport  as airport_a,
				radians(a1.longitude) as longitude_a,
				radians(a1.latitude) as latitude_a,
				f.arrival_airport as airport_b,
				radians(a2.longitude) as longitude_b,
				radians(a2.latitude) as latitude_b,
				f.aircraft_code,
				ac.range
		from flights f
		join aircrafts ac on f.aircraft_code =ac.aircraft_code
		join airports a1 on a1.airport_code =f.departure_airport
		join airports a2 on a2.airport_code =f.arrival_airport
		order by 1)t

		
		
		