WITH base AS (
    SELECT
        p.p_promo_id AS promo_id,
        d_sold.d_year AS year,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        SUM(ss.ss_net_paid) AS sales_amount,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(wr.wr_net_loss) AS web_return_loss,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
                           AND cr.cr_returned_time_sk = t_sold.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
                        AND wr.wr_returned_time_sk = t_sold.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2002
      AND p.p_channel_email = 'Y'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc LIKE '%defect%'
      AND cc.cc_state = 'TX'
      AND ws.web_country = 'United States'
      AND ss.ss_quantity > 1
    GROUP BY
        p.p_promo_id,
        d_sold.d_year,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
)
SELECT
    promo_id,
    year,
    profit_flag,
    SUM(sales_amount) AS total_sales,
    SUM(catalog_return_loss) AS total_catalog_return_loss,
    SUM(web_return_loss) AS total_web_return_loss,
    SUM(net_profit) AS total_net_profit,
    CASE WHEN SUM(net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
FROM base
GROUP BY ROLLUP (promo_id, year, profit_flag)
UNION DISTINCT
SELECT
    promo_id,
    year,
    profit_flag,
    SUM(sales_amount) AS total_sales,
    SUM(catalog_return_loss) AS total_catalog_return_loss,
    SUM(web_return_loss) AS total_web_return_loss,
    SUM(net_profit) AS total_net_profit,
    CASE WHEN SUM(net_profit) > 50000 THEN 'Medium' ELSE 'Low' END AS profit_category
FROM base
WHERE profit_flag = 'Loss'
GROUP BY ROLLUP (promo_id, year, profit_flag)
LIMIT 100
