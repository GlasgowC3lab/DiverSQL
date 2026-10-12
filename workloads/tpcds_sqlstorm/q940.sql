with sales_agg as (
   select 'store' as channel,
          ss.ss_item_sk as item_sk,
          ss.ss_sold_date_sk as date_sk,
          sum(ss.ss_net_paid) as total_net_paid,
          sum(ss.ss_net_profit) as total_net_profit,
          sum(ss.ss_quantity) as total_quantity
   from store_sales ss
   group by ss.ss_item_sk, ss.ss_sold_date_sk
   union all
   select 'web' as channel,
          ws.ws_item_sk as item_sk,
          ws.ws_sold_date_sk as date_sk,
          sum(ws.ws_net_paid) as total_net_paid,
          sum(ws.ws_net_profit) as total_net_profit,
          sum(ws.ws_quantity) as total_quantity
   from web_sales ws
   group by ws.ws_item_sk, ws.ws_sold_date_sk
   union all
   select 'catalog' as channel,
          cs.cs_item_sk as item_sk,
          cs.cs_sold_date_sk as date_sk,
          sum(cs.cs_net_paid) as total_net_paid,
          sum(cs.cs_net_profit) as total_net_profit,
          sum(cs.cs_quantity) as total_quantity
   from catalog_sales cs
   group by cs.cs_item_sk, cs.cs_sold_date_sk
),
returns_agg as (
   select 'store' as channel,
          sr.sr_item_sk as item_sk,
          sr.sr_returned_date_sk as date_sk,
          sum(sr.sr_net_loss) as total_return_loss,
          sum(sr.sr_return_quantity) as total_return_qty
   from store_returns sr
   group by sr.sr_item_sk, sr.sr_returned_date_sk
   union all
   select 'web' as channel,
          wr.wr_item_sk as item_sk,
          wr.wr_returned_date_sk as date_sk,
          sum(wr.wr_net_loss) as total_return_loss,
          sum(wr.wr_return_quantity) as total_return_qty
   from web_returns wr
   group by wr.wr_item_sk, wr.wr_returned_date_sk
   union all
   select 'catalog' as channel,
          cr.cr_item_sk as item_sk,
          cr.cr_returned_date_sk as date_sk,
          sum(cr.cr_net_loss) as total_return_loss,
          sum(cr.cr_return_quantity) as total_return_qty
   from catalog_returns cr
   group by cr.cr_item_sk, cr.cr_returned_date_sk
),
main_agg as (
   select
       s.channel,
       s.item_sk,
       s.date_sk,
       s.total_net_paid,
       s.total_net_profit,
       s.total_quantity,
       coalesce(r.total_return_loss, 0) as total_return_loss,
       coalesce(r.total_return_qty, 0) as total_return_qty,
       s.total_quantity - coalesce(r.total_return_qty, 0) as net_quantity,
       s.total_net_profit - coalesce(r.total_return_loss, 0) as net_profit_adj,
       case when s.total_net_profit - coalesce(r.total_return_loss,0) > 0 then 'POSITIVE' else 'NON_POSITIVE' end as profit_flag,
       case when r.total_return_loss is null then 'NO_RETURN' else 'RETURNED' end as return_status,
       d.d_date as sale_date,
       d.d_year as sale_year,
       i.i_product_name,
       i.i_category,
       i.i_class,
       i.i_brand
   from sales_agg s
   left join returns_agg r
       on s.channel = r.channel
      and s.item_sk = r.item_sk
      and s.date_sk = r.date_sk
   left join date_dim d
       on s.date_sk = d.d_date_sk
   left join item i
       on s.item_sk = i.i_item_sk
)
select
   ma.channel,
   ma.item_sk,
   ma.i_product_name,
   ma.i_category,
   ma.i_class,
   ma.i_brand,
   ma.sale_date,
   ma.total_quantity,
   ma.net_quantity,
   ma.total_net_paid,
   ma.total_net_profit,
   ma.total_return_loss,
   ma.net_profit_adj,
   ma.profit_flag,
   ma.return_status,
   concat(upper(ma.i_brand), ': ', ma.i_product_name) as product_label,
   row_number() over (partition by ma.channel order by ma.net_profit_adj desc) as channel_item_rank,
   sum(ma.net_profit_adj) over (partition by ma.channel order by ma.date_sk rows between 6 preceding and current row) as profit_7day_sum,
   avg(ma.net_profit_adj) over (partition by ma.item_sk order by ma.date_sk rows between 29 preceding and current row) as item_30day_avg_profit,
   (select avg(s2.total_net_profit - coalesce(r2.total_return_loss,0))
      from sales_agg s2
      left join returns_agg r2
        on s2.channel = r2.channel
       and s2.item_sk = r2.item_sk
       and s2.date_sk = r2.date_sk
      where s2.item_sk = ma.item_sk) as overall_item_avg_adj_profit
from main_agg ma
where
   (case when ma.channel = 'store' then ma.sale_year = 2002 else ma.sale_year = 2001 end)
   and ma.net_quantity > 0
   and (ma.total_net_profit - ma.total_return_loss) is not null
order by ma.net_profit_adj desc
limit 100
