---ИТОГОВАЯ РАБОТА “SQL и получение данных”

--task_1 В каких городах больше одного аэропорта?

/*В этом задании я вывел из таблицы airports все города, в которых есть аэропорты,
 * а также количество аэропортов в каждом, сгруппировав их по значению city.
 * Для фильтрации полей с агрег.функцией count по заданному условию я использовал оператор having. */

select city, count(airport_name) as quantity
from airports
group by 1
having count(airport_name)>1

----------------------------------------------------------------------------------------
--task_2 В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

/*В этом задании я написал подзапрос, в котором вывел из таблицы aircrafts самолёт с максимальной длительностью перелёта,
 * используя упорядочивание от большего к меньшему, и ограничив результат подзапроса первым значением
 * с помощью оператора limit.
 * Затем подзапрос я использовал в запросе, обогатив его информацией об аэропортах вылета из таблицы flights */

select distinct(f.departure_airport)as airport, t.aircraft_code as aircraft
from(
	select aircraft_code ,range 
	from aircrafts a 
	order by range desc
	limit 1)t
join flights f on f.aircraft_code=t.aircraft_code

----------------------------------------------------------------------------------------
--task_3 Вывести 10 рейсов с максимальным временем задержки вылета

/*В этом задании, используя таблицу flights, я вывел № рейсов, их ID, а также разность между реальным временем приземления
 * и временем, запланированным по расписанию. Я задал условие where, что данные по реальному времени приземления не содержат NULL.
 * Упорядочил значения разности от меньшего к большему, и ограничил результаты первыми 10 с помощью оператора limit.*/

select flight_no,flight_id ,actual_departure-scheduled_departure as dep_delay
from flights f 
where actual_departure is not null
order by dep_delay desc
limit 10 

----------------------------------------------------------------------------------------
--task_4 Были ли брони, по которым не были получены посадочные талоны?

/*В этом задании я вывел уникальные номера бронирований из таблицы bookings, 
 * с помощью left join обогатил полученные данные информацией о наличии посадочных талонов
 * из таблицы boarding_passes по № билетов(через join таблицы tickets по № бронирования) ,
 * которую так же вывел по условию where, где значение boarding_no содержит NULL.*/

select distinct(b.book_ref) ,bp.boarding_no
from bookings b 
join tickets t on t.book_ref =b.book_ref 
left join boarding_passes bp on bp.ticket_no =t.ticket_no 
where bp.boarding_no is null

----------------------------------------------------------------------------------------
--task_5 Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление 
--количества вывезенных пассажиров из каждого аэропорта на каждый день. 
--(Т.е. в этом столбце должна отражаться накопительная сумма - сколько 
--человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.)


/*В этом задании я использовал: 
 * подзапрос bp, в котором я вывел из таблицы boarding_passes ID перелётов и количество занятых на каждом из них мест,
 *  сгруппировав и упорядочив всё по ID перелётов;
 * подзапрос s, в котором я вывел из таблицы seats коды самолётов и количество имеющихся на борту мест,
 *  сгруппировав всё по коду самолёта.
 * Таблицу flights я обогатил информацией, присоединив эти подзапросы ("bp"-по общим ID перелётов, а "s"-по кодам самолётов).
 * Далее, в основном запросе, я вывел ID перелёта, код самолёта, код аэропорта, дату вылета,
 *  количество свободных мест, как разность количества всех имеющихся на борту мест и количества занятых мест,
 *  процент свободных мест от всех имеющихся в рамках перелёта с помощью оператора round и приведения данных в формат numeric.
 * При помощи оконной функции вывел накопительную сумму количества вывезенных пассажиров из каждого аэропорта за каждый день,
 *  и затем вывел количество пассажиров, летевших на каждом рейсе.
 * С помощью оператора where я задал условия, по которым столбцы с информацией по датам вылета и занятым на борту местам
 *  буддут содержать "NOT NULL-значения", и упорядочил данные по дате вылета.
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
--task_6 Найдите процентное соотношение перелетов по типам самолетов от общего количества.
	
/*В этом задании я использовал подзапрос t, в котором вывел из таблицы перелётов flights коды самолётов, совершающих перелёты.
 *Используя оконную функцию,я определил количество всех перелётов в рамках типа самолёта, 
 * группируя окна по типу самолёта с помощью partition by; далее этот результат я поделил на результат оконной функции,
 * выводящей общее количество всех совершённых перелётов, привёл полученные оконными функциями данные в формат numeric.
 *Далее я умножил результат деления на 100, и с помощью оператора round получил и вывел процентное значение перелётов на каждый тип самолёта.
 *
 *В основном запросе я вывел из результатов подзапроса t уникальные коды самолётов, а также процентное соотношение
 * перелётов для каждого типа самолетов от общего количества перелётов.*/

select 
	distinct aircraft_code,percent
from(
	select
		aircraft_code,
		round(count(flight_id)over(partition by aircraft_code)::numeric/count(flight_id)over()::numeric*100,1)as percent
	from flights)t
	
----------------------------------------------------------------------------------------
--task_7 Были ли города, в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
	
/*В этом задании я использовал ОТВ, в котором вывел:
 * ID перелётов, класс полёта пассажира и стоимость данного перелёта из таблицы ticket_flights,
 *  а также код и город аэропорта вылета из таблицы airports путём обогащения,
 *  объединив таблицу ticket_flights с таблицей flights по ID перелётов, а затем с таблицей airports по общим кодам аэропортов.
 * 	Полученные данные упорядочил по flight_id, fare_conditions и amount.
 * 
 * Далее, используя ОТВ, я вывел запросом список городов, сгруппированный по городам и ID перелётов,
 *  и с помощью оператора having произвёл фильтрацию результатов,
 *  по которой оператором case я задал условие, при котором наибольшее значение стоимости перелёта эконом-классом 
 *  должно быть больше наименьшего значения стоимости перелёта бизнес-классом в заданных рамках.*/

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
--task_8 Между какими городами нет прямых рейсов?

/*В этом задании я создал 2 представления:
 * В представлении all_variants я вывел все возможные сочетания городов, в которых есть аэропорты  из таблицы airports,
 *  используя декартово произведение в предложении from. Для того, чтобы не было зеркальных сочетаний, я задал условие через оператор where с оператором <.
 * В представлении known_flights я вывел сочетания названий городов вылета и городов прилёта, известных нам перелётов из таблицы flights,
 *  обогатив её данными из таблицы airports; сначала по равенству кодов аэропортов вылета с кодами из airports,
 *  затем по равенству кодов аэропортов прилёта с кодами из airports.
 * Здесь я также задал условие через оператор where с оператором <, по которому исключаются зеркальные результаты.
 * 
 * Далее, используя оператор except, я вывел все варианты сочетаний городов, исключая результаты запроса из представления known_flights,
 *  тем самым отобразив только сочетания городов, которые не имеют между собой известных нам прямых рейсов.
 * Для удобного восприятия результат запроса я упорядочил в алфавитном порядке.*/

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
--task_9 Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
--сравните с допустимой максимальной дальностью перелетов  в самолетах, 
--обслуживающих эти рейсы

/*В этом задании я использовал подзапрос t, в котором вывел из таблицы flights № перелёта, код самолёта, совершающего каждый перелёт,
 * их допустимую дальность перелётов за счёт обогащения таблицей aircrafts по коду самолёта,
 * аэропоры вылета и прилёта, а также приведённые с помощью оператора radians в радианы значения широты и долготы каждого из этих аэропортов
 * за счёт обогащения данными из таблицы airports,соединяя её сначала по коду аэропорта вылета, затем ещё раз по коду аэропорта прилёта.
 *Данные я упорядочил по № перелёта.
 * 
 *Далее, из подзапроса t я вывел № перелёта, маршрут перелёта (используя оператор concat и объединив коды аэропорта в одну строчку-маршрут),
 * с помощью оператора acos я рассчитал расстояние в километрах между аэропортами на маршруте по формуле:
 * acos(sin(latitude_a)*sin(latitude_b) + cos(latitude_a)*cos(latitude_b)*cos(longitude_a - longitude_b))*6371.
 *Затем, с помощью оператора case, я поставил условие, по которому при сравнении допустимой дальности перелёта с расстоянием между аэропортами в случае,
 * если расстояние меньше допустимой дальности, то ячейка примет значение "долетел", а в ином случае-"не долетел".*/

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

		
		
		