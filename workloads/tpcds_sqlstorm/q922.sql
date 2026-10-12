with
sales_keys as (
  select ss.ss_item_sk as i_item_sk, d.d_year, d.d_month_seq
  from store_sales ss
  join date_dim d on ss.ss_sold_date_sk = d.d_date_sk
  where d.d_year = 2001
  union
  select ws.ws_item_sk, d.d_year, d.d_month_seq
  from web_sales ws
  join date_dim d on ws.ws_sold_date_sk = d.d_date_sk
  where d.d_year = 2001
  union
  select cs.cs_item_sk, d.d_year, d.d_month_seq
  from catalog_sales cs
  join date_dim d on cs.cs_sold_date_sk = d.d_date_sk
  where d.d_year = 2001
),
store_sales_agg as (
  select
    ss.ss_item_sk as i_item_sk,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    sum(ss.ss_net_paid) as store_net_paid,
    sum(ss.ss_net_profit) as store_net_profit,
    sum(ss.ss_ext_discount_amt) as store_discount,
    count(*) as store_sales_cnt
  from store_sales ss
  join date_dim d on ss.ss_sold_date_sk = d.d_date_sk
  join item i on ss.ss_item_sk = i.i_item_sk
  where d.d_year = 2001
  group by ss.ss_item_sk, i.i_product_name, d.d_year, d.d_month_seq
),
web_sales_agg as (
  select
    ws.ws_item_sk as i_item_sk,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    sum(ws.ws_net_paid) as web_net_paid,
    sum(ws.ws_net_profit) as web_net_profit,
    sum(ws.ws_ext_discount_amt) as web_discount,
    count(*) as web_sales_cnt
  from web_sales ws
  join date_dim d on ws.ws_sold_date_sk = d.d_date_sk
  join item i on ws.ws_item_sk = i.i_item_sk
  where d.d_year = 2001
  group by ws.ws_item_sk, i.i_product_name, d.d_year, d.d_month_seq
),
catalog_sales_agg as (
  select
    cs.cs_item_sk as i_item_sk,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    sum(cs.cs_net_paid) as catalog_net_paid,
    sum(cs.cs_net_profit) as catalog_net_profit,
    sum(cs.cs_ext_discount_amt) as catalog_discount,
    count(*) as catalog_sales_cnt
  from catalog_sales cs
  join date_dim d on cs.cs_sold_date_sk = d.d_date_sk
  join item i on cs.cs_item_sk = i.i_item_sk
  where d.d_year = 2001
  group by cs.cs_item_sk, i.i_product_name, d.d_year, d.d_month_seq
),
store_returns_agg as (
  select
    sr.sr_item_sk as i_item_sk,
    d.d_year,
    d.d_month_seq,
    sum(sr.sr_net_loss) as store_net_loss,
    count(*) as store_return_cnt
  from store_returns sr
  join date_dim d on sr.sr_returned_date_sk = d.d_date_sk
  where d.d_year = 2001
  group by sr.sr_item_sk, d.d_year, d.d_month_seq
),
web_returns_agg as (
  select
    wr.wr_item_sk as i_item_sk,
    d.d_year,
    d.d_month_seq,
    sum(wr.wr_net_loss) as web_net_loss,
    count(*) as web_return_cnt
  from web_returns wr
  join date_dim d on wr.wr_returned_date_sk = d.d_date_sk
  where d.d_year = 2001
  group by wr.wr_item_sk, d.d_year, d.d_month_seq
),
catalog_returns_agg as (
  select
    cr.cr_item_sk as i_item_sk,
    d.d_year,
    d.d_month_seq,
    sum(cr.cr_net_loss) as catalog_net_loss,
    count(*) as catalog_return_cnt
  from catalog_returns cr
  join date_dim d on cr.cr_returned_date_sk = d.d_date_sk
  where d.d_year = 2001
  group by cr.cr_item_sk, d.d_year, d.d_month_seq
)
select
  sk.i_item_sk as item_sk,
  i.i_product_name as product_name,
  sk.d_year,
  sk.d_month_seq as month,
  coalesce(s.store_net_paid,0) + coalesce(w.web_net_paid,0) + coalesce(c.catalog_net_paid,0) as total_net_paid,
  (coalesce(s.store_net_profit,0) + coalesce(w.web_net_profit,0) + coalesce(c.catalog_net_profit,0)
   - coalesce(sr.store_net_loss,0) - coalesce(wr.web_net_loss,0) - coalesce(cr.catalog_net_loss,0)) as net_profit_after_returns,
  case when (coalesce(s.store_net_paid,0) + coalesce(w.web_net_paid,0) + coalesce(c.catalog_net_paid,0)) > 0
       then (coalesce(s.store_net_profit,0) + coalesce(w.web_net_profit,0) + coalesce(c.catalog_net_profit,0)
             - coalesce(sr.store_net_loss,0) - coalesce(wr.web_net_loss,0) - coalesce(cr.catalog_net_loss,0))
            / (coalesce(s.store_net_paid,0) + coalesce(w.web_net_paid,0) + coalesce(c.catalog_net_paid,0))
       else null end as profit_margin,
  (coalesce(s.store_discount,0) + coalesce(w.web_discount,0) + coalesce(c.catalog_discount,0))
   / nullif((coalesce(s.store_net_paid,0) + coalesce(w.web_net_paid,0) + coalesce(c.catalog_net_paid,0)),0) as avg_discount_rate,
  (coalesce(s.store_sales_cnt,0) + coalesce(w.web_sales_cnt,0) + coalesce(c.catalog_sales_cnt,0)) as total_sales_cnt,
  (coalesce(sr.store_return_cnt,0) + coalesce(wr.web_return_cnt,0) + coalesce(cr.catalog_return_cnt,0)) as total_return_cnt,
  row_number() over (partition by sk.d_year, sk.d_month_seq
                     order by (coalesce(s.store_net_profit,0) + coalesce(w.web_net_profit,0) + coalesce(c.catalog_net_profit,0)
                               - coalesce(sr.store_net_loss,0) - coalesce(wr.web_net_loss,0) - coalesce(cr.catalog_net_loss,0))
                              / nullif(coalesce(s.store_net_paid,0) + coalesce(w.web_net_paid,0) + coalesce(c.catalog_net_paid,0),0)
                              desc) as profit_rank
from sales_keys sk
join item i on i.i_item_sk = sk.i_item_sk
left join store_sales_agg s on s.i_item_sk = sk.i_item_sk and s.d_year = sk.d_year and s.d_month_seq = sk.d_month_seq
left join web_sales_agg w on w.i_item_sk = sk.i_item_sk and w.d_year = sk.d_year and w.d_month_seq = sk.d_month_seq
left join catalog_sales_agg c on c.i_item_sk = sk.i_item_sk and c.d_year = sk.d_year and c.d_month_seq = sk.d_month_seq
left join store_returns_agg sr on sr.i_item_sk = sk.i_item_sk and sr.d_year = sk.d_year and sr.d_month_seq = sk.d_month_seq
left join web_returns_agg wr on wr.i_item_sk = sk.i_item_sk and wr.d_year = sk.d_year and wr.d_month_seq = sk.d_month_seq
left join catalog_returns_agg cr on cr.i_item_sk = sk.i_item_sk and cr.d_year = sk.d_year and cr.d_month_seq = sk.d_month_seq
order by sk.d_year, sk.d_month_seq, profit_rank
limit 100
