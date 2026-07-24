with user_first_date as (
    select    user_id
            , min(date(time)) as global_first_date
    from user_actions
    group by user_id
),
orders_with_first_flag as (
    select ua.*
           , row_number() over (partition by user_id order by time) = 1 as is_first_order
           , global_first_date  as first_order_date
    from user_actions ua
    left join user_first_date ufd using(user_id)
    where order_id not in (select  order_id from user_actions where action = 'cancel_order')
)

select    date(time) as date
        , count(*) as orders
        , count(case when is_first_order then 1 end) as first_orders
        , count(case when date(time) = first_order_date then 1 end) as new_users_orders
        , round(100.0 * count(case when is_first_order then 1 end) / count(*), 2) as first_orders_share
        , round(100.0 * count(case when date(time) = first_order_date then 1 end) / count(*), 2) as new_users_orders_share
from orders_with_first_flag
group by date(time)
