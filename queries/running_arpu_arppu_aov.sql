with order_price_per_date as (
select        date
            , order_id
            , sum(price) as order_price
from products p
    join (select  creation_time::date as date
            , order_id
            , unnest(product_ids) as product_id
          from orders) o using(product_id)
where order_id not in (select order_id from user_actions where action = 'cancel_order')
group by date, order_id
),
daily_revenue as (
    select    date
            , sum(order_price) as revenue
            , count(order_id) as orders_count
    from order_price_per_date
    group by date
),
first_user_date as (
    select user_id, min(time::date) as date
    from user_actions
    group by user_id
),
running_users as (
    select date,
           sum(count(*)) over (order by date) as running_users_count
    from first_user_date
    group by date
),
first_paying_date as (
    select ua.user_id, min(ua.time::date) as date
    from user_actions ua
    where ua.order_id not in (select order_id from user_actions where action = 'cancel_order')
    group by ua.user_id
),
running_paying as (
    select date,
           sum(count(*)) over (order by date) as running_paying_count
    from first_paying_date
    group by date
),
running_all as (
    select coalesce(dr.date, ru.date, rp.date) as date,
           (dr.running_revenue) as running_revenue,
           (ru.running_users_count) as running_users_count,
           (rp.running_paying_count) as running_pay_users_count,
           (dr.running_orders_count) as running_orders_count
    from (
        select date,
               sum(revenue) over (order by date) as running_revenue,
               sum(orders_count) over (order by date) as running_orders_count
        from daily_revenue
    ) dr
    full join running_users ru using(date)
    full join running_paying rp using(date)
)
select    date 
        , round(running_revenue / running_users_count, 2) as running_arpu
        , round(running_revenue / running_pay_users_count, 2) as running_arppu
        , round(running_revenue / running_orders_count, 2) as running_aov
from running_all
order by date
