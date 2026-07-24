select    dt
        , count(distinct user_id) as active_users
        , count(distinct user_id)::float / max(count(distinct user_id)) over(partition by start_date) as percent_of_users
        , start_date
        , date_trunc('month', start_date) as start_month
        , date_trunc('month', dt) as month
        , dt -  start_date as dt_n
from 
(select   user_id
        , min(time::date) over(partition by user_id) as start_date
        , time::date as dt
from user_actions
)t1
group by dt, start_date
