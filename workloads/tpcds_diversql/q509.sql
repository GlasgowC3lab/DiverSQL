WITH
    sampled_sales AS (
        SELECT
            ss_sold_date_sk,
            ss_hdemo_sk,
            ss_ticket_number,
            ss_net_profit
        FROM store_sales TABLESAMPLE BERNOULLI (10)
    ),
    joined_all AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_net_profit,
            d.d_year,
            hd.hd_buy_potential,
            cc.cc_division_name,
            wp.wp_type,
            r.r_reason_desc
        FROM sampled_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN reason r ON r.r_reason_sk = wr.wr_reason_sk
        LEFT JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
        WHERE d.d_year = 1998
          AND hd.hd_buy_potential = '1000-2000'
          AND cc.cc_division_name IN (SELECT cc2.cc_division_name FROM call_center cc2 WHERE cc2.cc_employees > 200)
    ),
    ranked_sales AS (
        SELECT
            ss_ticket_number,
            d_year,
            hd_buy_potential,
            cc_division_name,
            wp_type,
            r_reason_desc,
            ss_net_profit,
            SUM(ss_net_profit) OVER (
                PARTITION BY d_year
                ORDER BY ss_net_profit DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS cum_profit,
            ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY ss_net_profit DESC) AS profit_rank,
            CASE
                WHEN ss_net_profit > 1000 THEN 'High'
                WHEN ss_net_profit > 0   THEN 'Medium'
                ELSE 'Low'
            END AS profit_category
        FROM joined_all
    ),
    top_sales AS (
        SELECT *
        FROM ranked_sales
        WHERE profit_rank <= 10
    )
SELECT
    f.ss_ticket_number,
    f.d_year,
    f.hd_buy_potential,
    f.cc_division_name,
    f.wp_type,
    f.r_reason_desc,
    f.cum_profit,
    f.profit_rank,
    f.profit_category,
    la.avg_profit
FROM top_sales f
CROSS JOIN LATERAL (
    SELECT AVG(j.ss_net_profit) AS avg_profit
    FROM joined_all j
    WHERE j.d_year = f.d_year
) la
UNION DISTINCT
SELECT
    o.ss_ticket_number,
    o.d_year,
    o.hd_buy_potential,
    o.cc_division_name,
    o.wp_type,
    o.r_reason_desc,
    o.cum_profit,
    o.profit_rank,
    o.profit_category,
    NULL AS avg_profit
FROM (
    SELECT
        rs.ss_ticket_number,
        rs.d_year,
        rs.hd_buy_potential,
        rs.cc_division_name,
        rs.wp_type,
        rs.r_reason_desc,
        rs.cum_profit,
        rs.profit_rank,
        rs.profit_category
    FROM ranked_sales rs
    WHERE NOT EXISTS (
        SELECT 1 FROM top_sales ts WHERE ts.ss_ticket_number = rs.ss_ticket_number
    )
) o
ORDER BY d_year DESC, profit_rank ASC
