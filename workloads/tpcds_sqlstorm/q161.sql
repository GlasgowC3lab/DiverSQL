with catalog_sales_base as (
  select d.d_year as year,
         d.d_moy as month,
         cc.cc_state as state,
         i.i_category as category,
         cs.cs_net_paid_inc_tax as sales_amount,
         cs.cs_net_profit as profit_amount,
         cs.cs_quantity as quantity,
         cs.cs_order_number as order_number,
         cs.cs_ext_discount_amt as discount_amount,
         cast(null as decimal(15,2)) as return_amount,
         cast(null as integer) as return_quantity,
         cast(null as integer) as return_order_number
  from catalog_sales cs
  join date_dim d on cs.cs_sold_date_sk = d.d_date_sk
  join call_center cc on cs.cs_call_center_sk = cc.cc_call_center_sk
  join promotion p on cs.cs_promo_sk = p.p_promo_sk
  join item i on cs.cs_item_sk = i.i_item_sk
  where p.p_discount_active = 'Y'
),
store_sales_base as (
  select d.d_year as year,
         d.d_moy as month,
         s.s_state as state,
         i.i_category as category,
         ss.ss_net_paid_inc_tax as sales_amount,
         ss.ss_net_profit as profit_amount,
         ss.ss_quantity as quantity,
         ss.ss_ticket_number as order_number,
         ss.ss_ext_discount_amt as discount_amount,
         cast(null as decimal(15,2)) as return_amount,
         cast(null as integer) as return_quantity,
         cast(null as integer) as return_order_number
  from store_sales ss
  join date_dim d on ss.ss_sold_date_sk = d.d_date_sk
  join store s on ss.ss_store_sk = s.s_store_sk
  join promotion p on ss.ss_promo_sk = p.p_promo_sk
  join item i on ss.ss_item_sk = i.i_item_sk
  where p.p_discount_active = 'Y'
),
web_sales_base as (
  select d.d_year as year,
         d.d_moy as month,
         ca.ca_state as state,
         i.i_category as category,
         ws.ws_net_paid_inc_tax as sales_amount,
         ws.ws_net_profit as profit_amount,
         ws.ws_quantity as quantity,
         ws.ws_order_number as order_number,
         ws.ws_ext_discount_amt as discount_amount,
         cast(null as decimal(15,2)) as return_amount,
         cast(null as integer) as return_quantity,
         cast(null as integer) as return_order_number
  from web_sales ws
  join date_dim d on ws.ws_sold_date_sk = d.d_date_sk
  join customer_address ca on ws.ws_ship_addr_sk = ca.ca_address_sk
  join promotion p on ws.ws_promo_sk = p.p_promo_sk
  join item i on ws.ws_item_sk = i.i_item_sk
  where p.p_discount_active = 'Y'
),
catalog_returns_base as (
  select d.d_year as year,
         d.d_moy as month,
         cc.cc_state as state,
         i.i_category as category,
         cast(null as decimal(15,2)) as sales_amount,
         cast(null as decimal(15,2)) as profit_amount,
         cast(null as integer) as quantity,
         cast(null as integer) as order_number,
         cast(null as decimal(15,2)) as discount_amount,
         cr.cr_net_loss as return_amount,
         cr.cr_return_quantity as return_quantity,
         cr.cr_order_number as return_order_number
  from catalog_returns cr
  join date_dim d on cr.cr_returned_date_sk = d.d_date_sk
  join call_center cc on cr.cr_call_center_sk = cc.cc_call_center_sk
  join item i on cr.cr_item_sk = i.i_item_sk
),
store_returns_base as (
  select d.d_year as year,
         d.d_moy as month,
         s.s_state as state,
         i.i_category as category,
         cast(null as decimal(15,2)) as sales_amount,
         cast(null as decimal(15,2)) as profit_amount,
         cast(null as integer) as quantity,
         cast(null as integer) as order_number,
         cast(null as decimal(15,2)) as discount_amount,
         sr.sr_net_loss as return_amount,
         sr.sr_return_quantity as return_quantity,
         sr.sr_ticket_number as return_order_number
  from store_returns sr
  join date_dim d on sr.sr_returned_date_sk = d.d_date_sk
  join store s on sr.sr_store_sk = s.s_store_sk
  join item i on sr.sr_item_sk = i.i_item_sk
),
web_returns_base as (
  select d.d_year as year,
         d.d_moy as month,
         ca.ca_state as state,
         i.i_category as category,
         cast(null as decimal(15,2)) as sales_amount,
         cast(null as decimal(15,2)) as profit_amount,
         cast(null as integer) as quantity,
         cast(null as integer) as order_number,
         cast(null as decimal(15,2)) as discount_amount,
         wr.wr_net_loss as return_amount,
         wr.wr_return_quantity as return_quantity,
         wr.wr_order_number as return_order_number
  from web_returns wr
  join date_dim d on wr.wr_returned_date_sk = d.d_date_sk
  join customer_address ca on wr.wr_refunded_addr_sk = ca.ca_address_sk
  join item i on wr.wr_item_sk = i.i_item_sk
),
combined as (
  select * from catalog_sales_base
  union all
  select * from store_sales_base
  union all
  select * from web_sales_base
  union all
  select * from catalog_returns_base
  union all
  select * from store_returns_base
  union all
  select * from web_returns_base
),
agg as (
  select
    year,
    month,
    state,
    category,
    sum(sales_amount) as total_sales,
    sum(profit_amount) as total_profit,
    sum(return_amount) as total_return_loss,
    sum(discount_amount) as total_discount,
    sum(quantity) as total_quantity,
    count(distinct order_number) as distinct_orders
  from combined
  where year = 2001
  group by year, month, state, category
)
select
  year,
  month,
  state,
  category,
  total_sales,
  total_profit,
  total_return_loss,
  total_sales - total_return_loss as net_sales,
  total_profit - total_return_loss as net_profit,
  total_discount,
  case when total_sales > 0 then total_discount / total_sales else null end as discount_ratio,
  total_quantity,
  distinct_orders,
  rank() over (partition by year, month order by (total_profit - total_return_loss) desc) as profit_rank
from agg
order by year, month, profit_rank
limit 200
