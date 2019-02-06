with orders as (select *
                from { { ref('stg_orders') } }
                where state != 'canceled'
                  and extract(year from completed_at) < '2018'
                  and email not like '%company.com'),
     order_items as (select * from { { ref('stg_order_items') } }),
     a as (select id,
                  number,
                  completed_at,
                  completed_at :: date as completed_at_date,
                  sum(total)           as net_rev,
                  sum(item_total)      as gross_rev,
                  count(id)            as order_count
           from orders
           group by completed_at_date),
     b as (select oi.order_id, o.completed_at :: date as completed_at_date, sum(oi.quantity) as qty
           from order_items oi
                    left join orders o on oi.order_id = o.id
           where (o.is_cancelled_order = false OR o.is_pending_order != true)
           group by completed_at_date),
     final as (select a.completed_at_date,
                      a.gross_rev,
                      a.net_rev,
                      b.qty,
                      a.order_count                   as orders,
                      b.qty / a.distinct_orders       as avg_unit_per_order,
                      a.Gross_Rev / a.distinct_orders as aov_gross,
                      a.Net_Rev / a.distinct_orders   as aov_net
               from a
                        join b on b.completed_at_date = a.completed_at_date
               where a.net_rev >= 150000)
select *
from final
order by completed_at_date desc