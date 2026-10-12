SELECT
    agg.d_year,
    agg.d_quarter_name,
    agg.s_state,
    agg.s_city,
    agg.web_market_manager,
    agg.p_promo_name,
    agg.avg_promo_cost,
    agg.num_returns,
    agg.total_return_amount,
    agg.total_return_tax,
    agg.total_net_loss,
    agg.total_return_qty,
    agg.discount_active_ratio,
    agg.total_return_amount / NULLIF(agg.avg_promo_cost, 0) AS return_to_cost_ratio,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year, agg.d_quarter_name ORDER BY agg.total_return_amount DESC) AS rank_by_return
FROM (
    SELECT
        d.d_year,
        d.d_quarter_name,
        s.s_state,
        s.s_city,
        ws.web_market_manager,
        p.p_promo_name,
        AVG(p.p_cost) AS avg_promo_cost,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(CASE WHEN p.p_discount_active = 'Y' THEN 1.0 ELSE 0.0 END) AS discount_active_ratio
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
      AND ws.web_country = 'United States'
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        s.s_state,
        s.s_city,
        ws.web_market_manager,
        p.p_promo_name
    HAVING SUM(wr.wr_return_amt) > 1000
) agg
ORDER BY agg.d_year, agg.d_quarter_name, agg.total_return_amount DESC
LIMIT 500
