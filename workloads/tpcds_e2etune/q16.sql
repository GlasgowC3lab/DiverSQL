WITH sales_by_promo_hour AS (
    SELECT
        td.t_hour,
        hd.hd_vehicle_count,
        p.p_promo_name,
        p.p_channel_tv,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_response_target = 1
      AND hd.hd_buy_potential = '1001-5000'
      AND hd.hd_vehicle_count > 0
    GROUP BY td.t_hour, hd.hd_vehicle_count, p.p_promo_name, p.p_channel_tv
    HAVING SUM(ss.ss_net_paid_inc_tax) > 5000
)
SELECT
    sbph.t_hour,
    sbph.hd_vehicle_count,
    sbph.p_promo_name,
    sbph.p_channel_tv,
    sbph.total_sales,
    sbph.avg_profit,
    sbph.unique_tickets,
    sbph.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY sbph.t_hour ORDER BY sbph.total_sales DESC) AS promo_sales_rank,
    SUM(sbph.total_sales) OVER (PARTITION BY sbph.t_hour ORDER BY sbph.total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_hour
FROM sales_by_promo_hour sbph
ORDER BY sbph.t_hour, promo_sales_rank
