with orders_cancel as(
    select    extract('hour'from creation_time)::integer as hour
            , count(order_id) as cnt_orders_cancel
    from orders
    where order_id in (select order_id from user_actions where action = 'cancel_order')
    group by hour
), 
orders_deliver as (
    select    extract('hour'from creation_time)::integer as hour
            , count(order_id) as cnt_orders_deliver
    from orders
    where order_id in (select order_id from courier_actions where action = 'deliver_order')
    group by hour
)
select hour
        , successful_orders
        , canceled_orders
        , round(canceled_orders::decimal / nullif(canceled_orders + successful_orders, 0), 2) as cancel_rate
from (
    select    coalesce(oc.hour, od.hour) as hour
            , coalesce(cnt_orders_deliver, 0) as successful_orders
            , coalesce(cnt_orders_cancel, 0) as canceled_orders
    from orders_cancel oc
        full join orders_deliver od using(hour)
    order by hour
     )t
order by hour
