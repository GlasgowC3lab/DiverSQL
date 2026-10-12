with sales_all as (
    select
        'catalog' as channel,
        cs.cs_sold_date_sk as date_sk,
        cs.cs_item_sk as item_sk,
        cs.cs_order_number as order_id,
        cs.cs_quantity as quantity,
        cs.cs_ext_sales_price as revenue,
        cs.cs_ext_tax as tax,
        cs.cs_net_paid as net_paid,
        cs.cs_net_profit as net_profit,
        cs.cs_promo_sk as promo_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        p.p_promo_id as p_promo_id,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    from catalog_sales cs
    join date_dim d on cs.cs_sold_date_sk = d.d_date_sk
    join item i on cs.cs_item_sk = i.i_item_sk
    left join promotion p on cs.cs_promo_sk = p.p_promo_sk
    where d.d_year = 2022 and d.d_qoy = 1
    union all
    select
        'store' as channel,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        p.p_promo_id as p_promo_id,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    from store_sales ss
    join date_dim d on ss.ss_sold_date_sk = d.d_date_sk
    join item i on ss.ss_item_sk = i.i_item_sk
    left join promotion p on ss.ss_promo_sk = p.p_promo_sk
    where d.d_year = 2022 and d.d_qoy = 1
    union all
    select
        'web' as channel,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        p.p_promo_id as p_promo_id,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    from web_sales ws
    join date_dim d on ws.ws_sold_date_sk = d.d_date_sk
    join item i on ws.ws_item_sk = i.i_item_sk
    left join promotion p on ws.ws_promo_sk = p.p_promo_sk
    where d.d_year = 2022 and d.d_qoy = 1
), item_agg as (
    select
        channel,
        i_item_id,
        i_item_desc,
        i_category,
        i_brand,
        p_promo_id,
        sum(revenue) as total_revenue,
        sum(quantity) as total_quantity,
        sum(net_profit) as total_profit,
        count(distinct order_id) as total_orders,
        avg(revenue / nullif(quantity, 0)) as avg_rev_per_qty,
        min(d_date) as first_sale_date,
        max(d_date) as last_sale_date,
        array_agg(distinct d_day_name) as sold_days,
        sum(tax) as total_tax
    from sales_all
    group by grouping sets (
        (channel, i_item_id, i_item_desc, i_category, i_brand, p_promo_id),
        (channel),
        ()
    )
), ranked as (
    select
        *,
        row_number() over (partition by channel order by total_revenue desc) as channel_item_rank,
        sum(total_revenue) over (partition by channel) as channel_total_revenue,
        sum(total_revenue) over () as grand_total_revenue
    from item_agg
    where i_item_id is not null
)
select
    channel,
    i_item_id,
    i_item_desc,
    i_category,
    i_brand,
    coalesce(p_promo_id, 'NO_PROMO') as promo_id,
    total_revenue,
    total_quantity,
    total_profit,
    total_orders,
    round(avg_rev_per_qty, 2) as avg_rev_per_qty,
    first_sale_date,
    last_sale_date,
    sold_days,
    total_tax,
    channel_item_rank,
    channel_total_revenue,
    round(total_revenue / nullif(channel_total_revenue, 0) * 100, 2) as revenue_pct_of_channel,
    round(total_revenue / nullif(grand_total_revenue, 0) * 100, 2) as revenue_pct_of_total
from ranked
where channel_item_rank <= 20
order by channel, channel_item_rank
limit 200
