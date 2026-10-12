with catalog_agg as (
    select
        cc.cc_call_center_sk,
        cc.cc_name,
        sum(coalesce(cs.cs_net_profit, 0)) as catalog_net_profit,
        sum(coalesce(cr.cr_net_loss, 0)) as catalog_net_loss,
        sum(coalesce(cs.cs_ext_sales_price, 0)) as catalog_sales_amount,
        sum(coalesce(cs.cs_quantity, 0)) as catalog_quantity,
        case
            when sum(coalesce(cs.cs_ext_sales_price, 0)) = 0 then null
            else sum(coalesce(cs.cs_net_profit, 0)) / sum(coalesce(cs.cs_ext_sales_price, 0))
        end as catalog_profit_ratio
    from catalog_sales cs
    left join catalog_returns cr on cs.cs_order_number = cr.cr_order_number
    left join call_center cc on cs.cs_call_center_sk = cc.cc_call_center_sk
    group by cc.cc_call_center_sk, cc.cc_name
),
store_agg as (
    select
        s.s_store_sk,
        s.s_store_name,
        sum(coalesce(ss.ss_net_profit, 0)) as store_net_profit,
        sum(coalesce(sr.sr_net_loss, 0)) as store_net_loss,
        sum(coalesce(ss.ss_ext_sales_price, 0)) as store_sales_amount,
        sum(coalesce(ss.ss_quantity, 0)) as store_quantity,
        rank() over (order by sum(coalesce(ss.ss_net_profit, 0)) desc) as store_profit_rank
    from store_sales ss
    left join store_returns sr on ss.ss_ticket_number = sr.sr_ticket_number
    left join store s on ss.ss_store_sk = s.s_store_sk
    group by s.s_store_sk, s.s_store_name
),
web_agg as (
    select
        w.web_site_sk,
        w.web_name,
        sum(coalesce(ws.ws_net_profit, 0)) as web_net_profit,
        sum(coalesce(wr.wr_net_loss, 0)) as web_net_loss,
        sum(coalesce(ws.ws_ext_sales_price, 0)) as web_sales_amount,
        sum(coalesce(ws.ws_quantity, 0)) as web_quantity,
        row_number() over (partition by w.web_site_sk order by sum(coalesce(ws.ws_net_profit, 0)) desc) as web_profit_seq
    from web_sales ws
    left join web_returns wr on ws.ws_order_number = wr.wr_order_number
    left join web_site w on ws.ws_web_site_sk = w.web_site_sk
    group by w.web_site_sk, w.web_name
),
combined as (
    select
        cast(cc_call_center_sk as varchar) as entity_id,
        cc_name as entity_name,
        'CALL_CENTER' as entity_type,
        catalog_net_profit as net_profit,
        catalog_net_loss as net_loss,
        catalog_sales_amount as sales_amount,
        catalog_quantity as quantity,
        catalog_profit_ratio as profit_ratio
    from catalog_agg
    union all
    select
        cast(s_store_sk as varchar),
        s_store_name,
        'STORE',
        store_net_profit,
        store_net_loss,
        store_sales_amount,
        store_quantity,
        null
    from store_agg
    union all
    select
        cast(web_site_sk as varchar),
        web_name,
        'WEB_SITE',
        web_net_profit,
        web_net_loss,
        web_sales_amount,
        web_quantity,
        null
    from web_agg
),
ranked as (
    select
        entity_id,
        entity_name,
        entity_type,
        net_profit,
        net_loss,
        sales_amount,
        quantity,
        profit_ratio,
        dense_rank() over (order by net_profit desc nulls last) as overall_profit_rank,
        case
            when sales_amount = 0 then null
            else net_profit / (sales_amount + 1)
        end as normalized_profit_metric,
        case
            when profit_ratio is null then 'UNKNOWN'
            when profit_ratio > 0.2 then 'HIGH'
            else 'LOW'
        end as profit_flag,
        case
            when entity_id IS DISTINCT FROM 'NULL' then 1
            else 0
        end as is_not_null_string
    from combined
),
avg_by_type as (
    select
        entity_type,
        avg(net_profit) as avg_profit_by_type
    from ranked
    group by entity_type
)
select
    r.entity_id,
    r.entity_name,
    r.entity_type,
    r.net_profit,
    r.net_loss,
    r.sales_amount,
    r.quantity,
    r.profit_ratio,
    r.overall_profit_rank,
    r.normalized_profit_metric,
    r.profit_flag,
    r.is_not_null_string,
    case
        when r.net_profit > (select a.avg_profit_by_type from avg_by_type a where a.entity_type = r.entity_type)
        then 'ABOVE_AVG'
        else 'BELOW_OR_EQUAL_AVG'
    end as profit_vs_avg,
    case
        when exists (
            select 1
            from catalog_returns cr
            where cr.cr_return_quantity is null
              and cr.cr_call_center_sk = cast(r.entity_id as integer)
        )
        then 1
        else 0
    end as has_null_return_qty
from ranked r
order by r.overall_profit_rank
limit 100
