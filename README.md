# SQL_Finals

Итоговая работа 

В работе использовался локальный тип подключения через импорт sql запроса из sql файла.

Краткое описание БД - из каких таблиц и представлений состоит.
Таблицы:

* aircrafts - содержит информацию о самолётах, совершающих рейсы.
* airports - содержит список аэропортов и их характеристики.
* boarding_passes - содержит данные по посадочным талонам.
* bookings - содержит информацию по бронированиям.
* flights - содержит данные каждого перелёта.
* seats - содержит информацию по местам в салоне каждого самолёта.
* ticket_flights - содержит данные по перелётам.
* tickets - содержит данные пассажиров

Представления:

* flights_v - содержит данные каждого перелёта и дополнительную информацию.

Мат.представления:

* routes - содержит информацию о маршрутах рейсов.

Развернутый анализ БД - описание таблиц, логики, связей и бизнес области (частично можно взять из описания базы данных, оформленной в виде анализа базы данных). Бизнес задачи, которые можно решить, используя БД.

Таблица aircrafts - содержит информацию о каждой модели самолёта, совершающей рейсы.
Каждая модель имеет свой трехзначный код (aircraft_code). Также указывается название модели (model) и максимальная дальность полета в км (range).

* Индексы: PRIMARY KEY, btree (aircraft_code)

* Ограничения-проверки: CHECK (range > 0) 

* Ссылки извне: TABLE "flights" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) 

TABLE "seats" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE


Таблица airports - содержит список аэропортов, каждый из которых идентифицируется трехбуквенным кодом (airport_code), имеет свое имя (airport_name) и город (city).
Также указывается широта (longitude), долгота (latitude) и часовой пояс (timezone) по месту нахождения.

* Индексы: PRIMARY KEY, btree (airport_code) 

* Ссылки извне: TABLE "flights" FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code) 

TABLE "flights" FOREIGN KEY (departure_airport) REFERENCES airports(airport_code)


Таблица boarding_passes - содержит данные по посадочным талонам с последовательными номерами(boarding_no) в порядке регистрации пассажиров на рейс (номер будет уникальным только в пределах конкретного  рейса) и номер места (seat_no) по этому талону. Таблица также содержит номер билета (ticket_no) и идентификационный номер рейса (flight_id)

* Индексы: PRIMARY KEY, btree (ticket_no, flight_id) 

UNIQUE CONSTRAINT, btree (flight_id, boarding_no) 

UNIQUE CONSTRAINT, btree (flight_id, seat_no) 

* Ограничения внешнего ключа: FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id) 


Таблица bookings - содержит информацию по бронированиям, такую как дата бронирования  (book_date, максимум за месяц до рейса, возможно бронирование на несколько пассажиров).  Бронирование идентифицируется номером (book_ref). Поле total_amount хранит общую стоимость включенных в бронирование перелетов всех пассажиров. 

* Индексы: PRIMARY KEY, btree (book_ref)

* Ссылки извне: TABLE "tickets" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)

Таблица flights - содержит данные каждого перелёта. Естественный ключ таблицы рейсов состоит из номера рейса (flight_no), и даты и времени отправления (scheduled_departure). Но для компактности внешних ключей в качестве первичного используется суррогатный ключ (flight_id). 
Рейс всегда соединяет две точки — аэропорты вылета (departure_airport) и прибытия (arrival_airport). Понятие «рейс с пересадками» отсутствует: если из одного аэропорта до другого нет прямого рейса, в билет просто включаются несколько необходимых рейсов. 
У каждого рейса есть запланированные дата и время вылета (scheduled_departure) и прибытия (scheduled_arrival). Реальные время вылета (actual_departure) и прибытия (actual_arrival) могут отличаться от запланированных, если рейс, например, задержан. 
Статус рейса (status) может принимать одно из 6 значений, в зависимости от обстоятельств: 
Scheduled (доступен для бронирования). Это происходит за месяц до плановой даты вылета; до этого запись о рейсе не существует в базе данных. 
On Time (доступен для регистрации, за сутки до плановой даты вылета, и не задержан). 
Delayed (доступен для регистрации, за сутки до плановой даты вылета, но задержан).
Departed (самолёт уже вылетел и находится в воздухе). 
Arrived (самолёт прибыл в пункт назначения).
Cancelled (рейс отменён).

* Индексы: PRIMARY KEY, btree (flight_id) 

UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure) 

* Ограничения-проверки: CHECK (scheduled_arrival > scheduled_departure) 

CHECK ((actual_arrival IS NULL) OR ((actual_departure IS NOT NULL AND actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure))) 

CHECK (status IN ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduled', 'Cancelled')) 

* Ограничения внешнего ключа: FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) 

FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code) 

FOREIGN KEY (departure_airport) REFERENCES airports(airport_code) 

* Ссылки извне: TABLE "ticket_flights" FOREIGN KEY (flight_id) REFERENCES flights(flight_id)


Таблица seats - содержит информацию по местам, определяемым своим номером  (seat_no) в салоне каждого самолёта (aircraft_code).Места определяют схему салона каждой модели. Каждое место имеет закрепленный за ним класс обслуживания (fare_conditions) — Economy, Comfort или Business.

* Индексы: PRIMARY KEY, btree (aircraft_code, seat_no) 

* Ограничения-проверки: CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))

* Ограничения внешнего ключа: FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE


Таблица ticket_flights - содержит данные по перелётам. Перелёт соединяет билет (ticket_no) с рейсом (flight_id). Для каждого перелета указываются его стоимость (amount) и класс обслуживания (fare_conditions).

* Индексы: PRIMARY KEY, btree (ticket_no, flight_id) 

* Ограничения-проверки: CHECK (amount >= 0) 

CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business')) 

* Ограничения внешнего ключа: FOREIGN KEY (flight_id) REFERENCES flights(flight_id) 

FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no) 

* Ссылки извне: TABLE "boarding_passes" FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)  


Таблица tickets - содержит уникальный номер билета (ticket_no), состоящий из 13 цифр. Билет содержит идентификатор пассажира (passenger_id) — номер документа, удостоверяющего личность, — его фамилию и имя (passenger_name) и контактную информацию (contact_data). 

Ни идентификатор пассажира, ни имя не являются постоянными (можно поменять паспорт, можно сменить фамилию), поэтому однозначно найти все билеты одного и того же пассажира невозможно. 

* Индексы: PRIMARY KEY, btree (ticket_no) 

* Ограничения внешнего ключа: FOREIGN KEY (book_ref) REFERENCES bookings(book_ref) 

* Ссылки извне: TABLE "ticket_flights" FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)


Представление flights_v - созданное над таблицей flights, содержит дополнительную информацию:

- расшифровку данных об аэропорте вылета (departure_airport, departure_airport_name, departure_city)

- расшифровку данных об аэропорте прибытия (arrival_airport, arrival_airport_name, arrival_city)

- местное время вылета (scheduled_departure_local, actual_departure_local)

- местное время прибытия (scheduled_arrival_local, actual_arrival_local)

- продолжительность полета (scheduled_duration, actual_duration).


Материализованное представление routes - содержит информацию о маршруте, которая не зависит от конкретных дат рейсов:

- номер рейса (flight_no)

- код аэропорта отправления (departure_airport)

- название аэропорта отправления (departure_airport_name)

- город отправления (departure_city)

- код аэропорта прибытия (arrival_airport)

- название аэропорта прибытия (arrival_airport_name)

- город прибытия (arrival_city)

- код самолёта (aircraft_code)

- продолжительность полёта (duration)

- дни недели, когда совершаются рейсы (days_of_week)


Функция now - демонстрационная база содержит временной «срез» данных. Позиция «среза» сохранена в функции bookings.now(). Ей можно пользоваться в запросах там, где в обычной жизни использовалась бы функция now(). Кроме того, значение этой функции определяет версию демонстрационной базы данных. Актуальная версия на текущий момент — от 13.10.2016. 


Бизнес задачи, которые можно решить, используя БД:

Используя данные базы можно, например:

* найти рейсы, пользующиеся наименьшим спросом в конкретный временной период, чтобы скорректировать расписание перелётов, и сэкономить на перелётах с низким количеством занятых пассажирами мест.
* или наоборот, простимулировать спрос на такие рейсы за счёт маркетинговых акций.

* основываясь на билетах, в рамках которых пассажиры осуществляют перелёты “с пересадками”, выявить наиболее актуальные направления для запуска прямых рейсов по ним.
* скорректировать стоимость билетов в периоды наибольшей загруженности рейсов для увеличения прибыли с перелётов по актуальным направлениям.
* выявить наиболее вероятные причины задержек рейсов, чтобы в дальнейшем исключать все возможные проблемы, зависящие от авиаперевозчика (при наличии отчётов о причинах задержек рейсов).
