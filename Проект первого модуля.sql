/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Владимиров Николай Александрович
 * Дата: 03.09.2025
*/
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
    count_share_st as 
    (
    select 
      count(a.id) as count_share_st 
    from real_estate.flats as f
    inner join real_estate.city as c on f.city_id = c.city_id
    inner join real_estate.advertisement as a on f.id = a.id
    where city = 'Санкт-Петербург' and (a.first_day_exposition >= '2015-01-01' and a.first_day_exposition <= '2018-12-31')
    and a.id IN (SELECT * FROM filtered_id)
    ),
    count_share_len_obl as
    (
    	select 
    	count(a.id) as count_share_len_obl
    	from real_estate.flats as f
    	inner join real_estate.city as c on f.city_id = c.city_id
    	inner join real_estate.type as t on f.type_id = t.type_id
    	inner join real_estate.advertisement as a on f.id = a.id
    	where type = 'город' and city <> 'Санкт-Петербург' and (a.first_day_exposition >= '2015-01-01' and a.first_day_exposition <= '2018-12-31')
    	and a.id IN (SELECT * FROM filtered_id)
    ),
info_st as(
	select
	 case when a.days_exposition >= 1 and a.days_exposition <= 30
		 then '1 month'
		 when a.days_exposition >= 31 and a.days_exposition <= 90
		 then '1-3 months'
		 when a.days_exposition >= 91 and a.days_exposition <= 180 
		 then '3-6 month'
		 when a.days_exposition >= 181
		 then '6 month >'
		 when a.days_exposition is null
		 then 'non category'
	 end as category_time,
	 case when c.city = 'Санкт-Петербург'
		 then 'Санкт-Петербург'
		 else 'города Ленинградской области'
	 end as city_region,
	 count(a.id) as count_flats,
	 round(avg(a.last_price)::numeric, 2) as avg_price,
	 round(avg(f.total_area)::numeric, 2) as avg_area,
	 round(avg(a.last_price/ f.total_area)::numeric, 2) as avg_price_m2,
	 PERCENTILE_DISC(0.5) within group(order by f.rooms) as m_rooms,
	 PERCENTILE_DISC(0.5) within group(order by f.balcony) as m_balcony
	FROM real_estate.flats as f 
	left join real_estate.advertisement as a on f.id = a.id
	left join real_estate.city as c on f.city_id = c.city_id
	left join real_estate.type as t on f.type_id = t.type_id 
	WHERE a.id IN (SELECT * FROM filtered_id) and (a.first_day_exposition >= '2015-01-01' and a.first_day_exposition <= '2018-12-31')
	and type = 'город'
	group by category_time, city_region
	)
select
	category_time,
	count_flats,
	round((count_flats::numeric / st.count_share_st * 100.0), 2) as share,
	avg_price,
	avg_area,
	avg_price_m2,
	m_rooms,
	m_balcony,
	city_region
from info_st
cross join count_share_st as st
where city_region = 'Санкт-Петербург'
union all
select
	category_time,
	count_flats,
	round((count_flats::numeric / lobl.count_share_len_obl * 100.0), 2) as share,
	avg_price,
	avg_area,
	avg_price_m2,
	m_rooms,
	m_balcony,
	city_region
from info_st
cross join count_share_len_obl as lobl
where city_region <> 'Санкт-Петербург'
order by city_region, category_time;
/*
category_time|count_flats|share|avg_price  |avg_area|avg_price_m2|m_rooms|m_balcony|city_region                 |
-------------+-----------+-----+-----------+--------+------------+-------+---------+----------------------------+
1 month      |       1794|15.99| 6092949.22|   54.66|   108919.78|      2|      1.0|Санкт-Петербург             |
1-3 months   |       3020|26.92| 6473286.13|   56.58|   110874.32|      2|      1.0|Санкт-Петербург             |
3-6 month    |       2244|20.01| 6998081.82|   60.55|   111973.67|      2|      1.0|Санкт-Петербург             |
6 month >    |       3506|31.26| 7980344.62|   65.76|   114981.07|      2|      1.0|Санкт-Петербург             |
non category |        653| 5.82|11418045.70|   81.38|   136107.66|      3|      1.0|Санкт-Петербург             |
__________________________________________________________________________________________________________________

1 month      |        340|12.02| 3500117.40|   48.75|    71907.63|      2|      1.0|города Ленинградской области|
1-3 months   |        864|30.55| 3417498.14|   50.85|    67423.80|      2|      1.0|города Ленинградской области|
3-6 month    |        553|19.55| 3620472.79|   51.83|    69809.30|      2|      1.0|города Ленинградской области|
6 month >    |        873|30.87| 3773134.33|   55.03|    68215.11|      2|      1.0|города Ленинградской области|
non category |        198| 7.00| 4674793.98|   62.78|    72925.89|      2|      1.0|города Ленинградской области|*/

--По выгруженным данным видно:
--В городах Ленинградской области отлично продаются квартиры с ср.ценой 67423 руб кв/м и ср. площадью 50,85 кв/м доля рынка таких квартир - 30%, сделки закрываются за 1-3 месяца.
--Так же 30% доля рынка занимают квартиры, которые имеют средние параметры: 68211 руб кв/м и площадь 55,03 кв/м, но такие сделки закрываются дольше - более 6 месяцев.
--Сделки, которые закрываются быстро имеют высокую цену за кв.м. - 71907 руб кв/м, но доля рынка всего 12%.
--Плохой спрос имеют квартиры "премимум сегмента" для город Лен. области - цена за кв. м. 72925 руб и ср. площадь - 62,78.

-- В Санкт-Петербурге объявления, которые были активны меньше 1 месяца, имеют долю продаж 16% - больше чем аналогичный сегмент в Лен.области(12%), 
--скорее всего это связано с большей привлекательностью квартир в турестическом городе для инвесторов недвижимости и большей доступностью по цене относительно других объектов в Санкт-Петербурге.
--Отличные продажи показывает сегмент квартир с ср. парметрами - 65,76 кв/м и ценой 114981,07 руб кв/м, доля рынка 31%, но время продажи больше 6 месяцев, это говорит о том, что 
--в городах Лен.области в Санкт- Пербурге люди готовы подождать ради квартиры с большей площадью. 
--Так же хорошие доли рынка занимают сделки, которые закрыли за 1-3 месяца - 27% и 3-6 месяцев - 20% - общ. ср. площадь таких квартир 56-60 кв.м и цена 110874 - 111973 руб кв/м
--такие квартиры доступнее по цене чем категория "больше 6 месяцев", поэтому продаются быстрее. 
--Так же как и в Лен.области в Санкт-Петербурге плохие продажи имеют квартиры "премиум сегмента" 5,82% доля рынка ср. цена за квартиру 11 418 042 рублей


WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
info_month_first as(
	select
	 extract('month' from a.first_day_exposition) as month_public,
	 --extract('month' from (a.first_day_exposition + (a.days_exposition || ' days')::interval)) as month_sell,
	 count(a.id) as count_public,
	 round(avg(a.last_price)::numeric, 2) as avg_price,
	 round(avg(f.total_area)::numeric, 2) as avg_area
	FROM real_estate.flats as f 
	inner join real_estate.advertisement as a on f.id = a.id
	inner join real_estate.type as t on f.type_id = t.type_id 
	WHERE f.id IN (SELECT * FROM filtered_id) and (a.first_day_exposition >= '2015-01-01' and a.first_day_exposition <= '2018-12-31')
	and type = 'город'
	group by month_public
	),
info_month_sell as(
	select
	 extract('month' from (a.first_day_exposition + (a.days_exposition || ' days')::interval)) as month_sell,
	 count(a.id) as count_sell,
	 round(avg(a.last_price)::numeric, 2) as avg_price,
	 round(avg(f.total_area)::numeric, 2) as avg_area
	FROM real_estate.flats as f 
	inner join real_estate.advertisement as a on f.id = a.id
	inner join real_estate.type as t on f.type_id = t.type_id
	WHERE f.id IN (SELECT * FROM filtered_id) and (a.first_day_exposition between '2015-01-01' AND '2018-12-31')
	and type = 'город' and extract('month' from (a.first_day_exposition + (a.days_exposition || ' days')::interval)) is not NULL
	group by month_sell),
count_public as 
    (
    select 
    	count(a.id) as count_public 
    from real_estate.flats as f
    inner join real_estate.advertisement as a on f.id = a.id
    inner join real_estate.type as t on f.type_id = t.type_id
    where type = 'город' and (a.first_day_exposition >= '2015-01-01' and a.first_day_exposition <= '2018-12-31')
    and a.id IN (SELECT * FROM filtered_id)
    ),
count_sell as
    (
    select 
    	count(a.id) as count_sell
    from real_estate.flats as f
    inner join real_estate.type as t on f.type_id = t.type_id
    inner join real_estate.advertisement as a on f.id = a.id
    where type = 'город' and (a.first_day_exposition >= '2015-01-01' and a.first_day_exposition <= '2018-12-31')
    and a.id IN (SELECT * FROM filtered_id) and days_exposition is not null
    )
select
	f.month_public as N,
	case 
	when f.month_public = 1
	then 'Январь'
	when f.month_public = 2
	then 'Февраль'
	when f.month_public = 3
	then 'Март'
	when f.month_public = 4
	then 'Апрель'
	when f.month_public = 5
	then 'Май'
	when f.month_public = 6
	then 'Июнь'
	when f.month_public = 7
	then 'Июль'
	when f.month_public = 8
	then 'Август'
	when f.month_public = 9
	then 'Сентябрь'
	when f.month_public = 10
	then 'Октябрь'
	when f.month_public = 11
	then 'Ноябрь'
	when f.month_public = 12
	then 'Декабрь'
	end as month,
	f.count_public,
	round((f.count_public::numeric * 100 / pub.count_public), 2) as share_pub,
	s.count_sell,
	round((s.count_sell::numeric / sell.count_sell * 100), 2) as share_sell,
	f.avg_price as pub_avg_price,
	s.avg_price as sell_avg_price,
	f.avg_area as pub_avg_area,
	s.avg_area as sell_avg_area,
	round((f.avg_price::numeric/f.avg_area), 2) as pub_avg_price_m2,
	round((s.avg_price::numeric/s.avg_area), 2) as sell_avg_price_m2
from info_month_first as f 
left join info_month_sell as s on f.month_public = s.month_sell
cross join count_public as pub
cross join count_sell as sell
order by N
/*
n |month   |count_public|share_pub|count_sell|share_sell|pub_avg_price|sell_avg_price|pub_avg_area|sell_avg_area|pub_avg_price_m2|sell_avg_price_m2|
--+--------+------------+---------+----------+----------+-------------+--------------+------------+-------------+----------------+-----------------+
 1|Январь  |         735|     5.23|      1225|      9.28|   6631697.46|    6388680.83|       59.16|        57.53|       112097.66|        111049.55|
 2|Февраль |        1369|     9.75|      1048|      7.94|   6541457.72|    6538414.92|       60.10|        61.12|       108842.89|        106976.68|
 3|Март    |        1119|     7.97|      1071|      8.12|   6357724.99|    6921579.09|       60.00|        60.37|       105962.08|        114652.63|
 4|Апрель  |        1021|     7.27|      1031|      7.81|   6672755.22|    6272418.21|       60.60|        59.22|       110111.47|        105917.23|
 5|Май     |         891|     6.34|       729|      5.53|   6324644.53|    5996141.43|       59.19|        57.78|       106853.26|        103775.38|
 6|Июнь    |        1224|     8.71|       771|      5.84|   6440384.82|    6382216.47|       58.37|        59.82|       110337.24|        106690.35|
 7|Июль    |        1149|     8.18|      1108|      8.40|   6565639.54|    6316116.57|       60.42|        58.54|       108666.66|        107894.03|
 8|Август  |        1166|     8.30|      1137|      8.62|   6690968.80|    5914257.20|       58.99|        56.83|       113425.48|        104069.28|
 9|Сентябрь|        1341|     9.55|      1238|      9.38|   6829994.21|    6253290.09|       61.04|        57.49|       111893.75|        108771.79|
10|Октябрь |        1437|    10.23|      1360|     10.31|   6464010.32|    6302285.29|       59.43|        58.86|       108766.79|        107072.47|
11|Ноябрь  |        1569|    11.17|      1301|      9.86|   6541756.73|    6240427.76|       59.58|        56.71|       109797.86|        110041.05|
12|Декабрь |        1024|     7.29|      1175|      8.91|   6494968.00|    6465784.20|       58.84|        59.26|       110383.55|        109108.74|

-Самый активный месяц по публикациям Ноябрь с долей 11,17%
-С августа идет активный рост публикаций, это связано с подготовкой к высокому сезону продаж.
-Наблюдается рост цены в августе 113425.48 руб кв/м относительно июля 108666.66 руб кв/м, так же связано с подготовкой к сезону продаж.
-Самый непубликуемый месяц - январь доля 5,23% и Май с долей 6,34% - в этих месяцах много праздничных выходных. 

-Самый активный месяц по продажам - Октябрь с долей рынка 10,31%, это подтверждает осене-зимний пик продаж.
-Самый плохой месяц по продажам - Май с долей 5,53% и Июнь с долей 5,84% рынка. Плохие продажи связаны с началом дачного сезона, праздниками и началом отпусков.
-Не смотря на то, что в январе много праздничных дней и высокие цена за кв.м. - 112097,66 руб доля продаж составляет 9,28%. Теория: хороший пред- и после- новогодлний маркетинг
влияет на продажи в январе и многие получают новогодние премии и 13ю зарплату, что может стимулировать покупки. */