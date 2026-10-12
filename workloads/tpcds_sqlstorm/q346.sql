with cat_sales as (
    select
        d.d_year,
        d.d_month_seq as month_seq,
        i.i_category,
        i.i_category_id,
        sum(cs.cs_ext_discount_amt) as total_discount,
        sum(cs.cs_net_paid) as total_net_paid,
        sum(cs.cs_net_profit) as total_net_profit,
        count(distinct cs.cs_order_number) as orders,
        count(distinct cs.cs_item_sk) as distinct_items
    from catalog_sales cs
    join date_dim d on cs.cs_sold_date_sk = d.d_date_sk
    join item i on cs.cs_item_sk = i.i_item_sk
    where cs.cs_net_paid > 0
    group by d.d_year, d.d_month_seq, i.i_category, i.i_category_id
),
store_sales_agg as (
    select
        d.d_year,
        d.d_month_seq as month_seq,
        i.i_category,
        i.i_category_id,
        sum(ss.ss_ext_discount_amt) as total_discount,
        sum(ss.ss_net_paid) as total_net_paid,
        sum(ss.ss_net_profit) as total_net_profit,
        count(distinct ss.ss_ticket_number) as orders,
        count(distinct ss.ss_item_sk) as distinct_items
    from store_sales ss
    join date_dim d on ss.ss_sold_date_sk = d.d_date_sk
    join item i on ss.ss_item_sk = i.i_item_sk
    where ss.ss_net_paid > 0
    group by d.d_year, d.d_month_seq, i.i_category, i.i_category_id
),
web_sales_agg as (
    select
        d.d_year,
        d.d_month_seq as month_seq,
        i.i_category,
        i.i_category_id,
        sum(ws.ws_ext_discount_amt) as total_discount,
        sum(ws.ws_net_paid) as total_net_paid,
        sum(ws.ws_net_profit) as total_net_profit,
        count(distinct ws.ws_order_number) as orders,
        count(distinct ws.ws_item_sk) as distinct_items
    from web_sales ws
    join date_dim d on ws.ws_sold_date_sk = d.d_date_sk
    join item i on ws.ws_item_sk = i.i_item_sk
    where ws.ws_net_paid > 0
    group by d.d_year, d.d_month_seq, i.i_category, i.i_category_id
),
combined_sales as (
    select 'catalog' as channel, *
    from cat_sales
    union all
    select 'store' as channel, *
    from store_sales_agg
    union all
    select 'web' as channel, *
    from web_sales_agg
),
sales_with_rank as (
    select
        cs.channel,
        cs.d_year,
        cs.month_seq,
        cs.i_category,
        cs.i_category_id,
        cs.total_discount,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.orders,
        cs.distinct_items,
        row_number() over (partition by cs.d_year, cs.month_seq, cs.i_category order by cs.total_net_profit desc) as profit_rank,
        sum(cs.total_net_profit) over (partition by cs.d_year, cs.month_seq) as month_total_profit,
        sum(cs.total_net_profit) over (partition by cs.i_category order by cs.d_year, cs.month_seq rows between unbounded preceding and current row) as cumulative_profit_category
    from combined_sales cs
),
category_stats as (
    select
        swr.d_year,
        swr.month_seq,
        swr.i_category,
        swr.i_category_id,
        max(case when swr.profit_rank = 1 then swr.channel end) as top_channel,
        max(case when swr.profit_rank = 1 then swr.total_net_profit end) as top_channel_profit,
        sum(swr.total_net_profit) as sum_profit_all_channels,
        avg(swr.total_discount) as avg_discount_all_channels,
        sum(case when swr.total_net_paid > 0 then 1 else 0 end) as nonzero_paid_rows,
        case when sum(swr.total_net_profit) = 0 then null else max(case when swr.profit_rank = 1 then swr.total_net_profit end) / sum(swr.total_net_profit) end as top_profit_ratio
    from sales_with_rank swr
    group by swr.d_year, swr.month_seq, swr.i_category, swr.i_category_id
),
final_stats as (
    select
        cs.*,
        (select avg(sub.sum_profit_all_channels)
         from category_stats sub
         where sub.d_year = cs.d_year and sub.month_seq = cs.month_seq) as month_avg_profit_all_categories,
        coalesce(cs.top_profit_ratio, 0) as top_profit_ratio_coalesced,
        concat('Y', CAST(cs.d_year AS VARCHAR), '-M', lpad(CAST(cs.month_seq AS VARCHAR), 2, '0'), '-', cs.i_category, '-', coalesce(cs.top_channel, 'none')) as label
    from category_stats cs
),
store_call_join as (
    select
        fs.*,
        s.s_store_name,
        cc.cc_name as call_center_name,
        coalesce(s.s_store_name, cc.cc_name, 'unknown') as primary_location_name,
        case 
            when fs.label like '%Electronics%' then 'Electronics Category'
            when fs.label like '%Clothing%' then 'Clothing Category'
            else 'Other'
        end as category_group
    from final_stats fs
    left join store s on s.s_store_sk = (fs.month_seq % 1000)
    left join call_center cc on cc.cc_call_center_sk = (fs.month_seq % 500)
)
select
    scj.d_year,
    scj.month_seq,
    scj.i_category,
    scj.top_channel,
    scj.top_channel_profit,
    round(scj.sum_profit_all_channels, 2) as sum_profit_all_channels,
    round(scj.avg_discount_all_channels, 2) as avg_discount_all_channels,
    scj.nonzero_paid_rows,
    round(scj.top_profit_ratio_coalesced, 4) as top_profit_ratio,
    round(scj.month_avg_profit_all_categories, 2) as month_avg_profit_all_categories,
    scj.primary_location_name,
    scj.category_group,
    scj.label
from store_call_join scj
where
    (scj.primary_location_name is not null and scj.primary_location_name <> 'unknown')
    and (coalesce(scj.top_channel, '') <> '')
    and (scj.label is not null and regexp_like(scj.label, '^Y\\d{4}-M\\d{2}-.+$'))
    and (scj.month_seq between 1 and 12)
order by
    scj.d_year desc,
    scj.month_seq,
    scj.sum_profit_all_channels desc
limit 100
