with order_price_per_date as (
select        o.date
            , o.order_id 
            , user_id
            , sum(price) as order_price
from products p
    join (select  creation_time::date as date
            , order_id
            , unnest(product_ids) as product_id
          from orders) o using(product_id)
    join (select distinct order_id, user_id from user_actions) ua on o.order_id = ua.order_id
    where o.order_id not in (select order_id from user_actions where action = 'cancel_order')
group by o.date, o.order_id, user_id
),
daily_revenue as (
    select    date
            , sum(order_price) as revenue
            , count(order_id) as orders_count
    from order_price_per_date
    group by date
),
first_user_date as(
    select    min(time::date) as first_date
            , user_id
    from user_actions
    group by user_id
),
daily_revenue_new_users as (
    select    op.date as date
            , sum(op.order_price) as new_users_revenue
    from order_price_per_date op
    join first_user_date fu on op.user_id = fu.user_id
    where op.date = fu.first_date
    group by op.date
)
select    coalesce(dr.date, dru.date) as date
        , dr.revenue
        , dru.new_users_revenue
        , round(new_users_revenue / revenue * 100, 2) as new_users_revenue_share
        , round((revenue - new_users_revenue) / revenue * 100, 2) as old_users_revenue_share
    from daily_revenue dr 
        left join daily_revenue_new_users dru on dru.date = dr.date
order by dr.date
