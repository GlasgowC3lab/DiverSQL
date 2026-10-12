WITH sales AS (
    SELECT
        s.ss_customer_sk AS customer_sk,
        d.d_year AS year,
        s.ss_net_profit AS profit,
        'store' AS channel,
        i.i_category AS category,
        s.ss_quantity AS qty,
        s.ss_net_paid AS net_paid
    FROM store_sales s
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN item i ON s.ss_item_sk = i.i_item_sk
    WHERE s.ss_quantity > 0
    UNION ALL
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        cs.cs_net_profit AS profit,
        'catalog' AS channel,
        i.i_category AS category,
        cs.cs_quantity AS qty,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_quantity > 0
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        ws.ws_net_profit AS profit,
        'web' AS channel,
        i.i_category AS category,
        ws.ws_quantity AS qty,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity > 0
),
returns AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_year AS year,
        -sr.sr_net_loss AS return_amount,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        d.d_year AS year,
        -cr.cr_net_loss AS return_amount,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        d.d_year AS year,
        -wr.wr_net_loss AS return_amount,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN c.c_birth_year IS NULL THEN 'UNKNOWN'
            ELSE CAST(c.c_birth_year AS VARCHAR)
        END AS birth_year_str
    FROM customer c
    LEFT JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
),
category_year_avg AS (
    SELECT
        category,
        year,
        AVG(profit) AS avg_profit_per_category_year
    FROM sales
    GROUP BY category, year
),
multi_channel_customers AS (
    SELECT customer_sk FROM sales WHERE channel = 'store'
    INTERSECT
    SELECT customer_sk FROM sales WHERE channel = 'web'
),
sales_with_returns AS (
    SELECT
        s.customer_sk,
        s.year,
        s.channel,
        s.category,
        s.profit,
        COALESCE(r.return_amount, 0) AS return_amount,
        s.profit - COALESCE(r.return_amount, 0) AS net_profit,
        c.full_name,
        c.pref_flag,
        c.ca_city,
        c.ca_state,
        ROW_NUMBER() OVER (PARTITION BY s.customer_sk, s.year ORDER BY s.profit - COALESCE(r.return_amount, 0) DESC) AS profit_rank,
        CASE 
            WHEN s.profit - COALESCE(r.return_amount, 0) > 0 THEN 'PROFITABLE'
            ELSE 'NON-PROFITABLE'
        END AS profitability_flag,
        CONCAT(SUBSTR(c.full_name, 1, 3), '_', CAST(s.customer_sk AS VARCHAR)) AS customer_code,
        COALESCE(cy.avg_profit_per_category_year, 0) AS category_avg_profit,
        (s.profit - COALESCE(r.return_amount, 0)) / NULLIF(cy.avg_profit_per_category_year, 0) AS profit_vs_avg_ratio,
        (SELECT MIN(d_inner.d_date)
         FROM date_dim d_inner
         JOIN sales s_inner ON s_inner.year = d_inner.d_year
         WHERE s_inner.customer_sk = s.customer_sk) AS first_sale_date,
        (SELECT COUNT(DISTINCT d_inner.d_month_seq)
         FROM date_dim d_inner
         WHERE d_inner.d_year = s.year) AS months_in_year
    FROM sales s
    LEFT JOIN returns r
        ON s.customer_sk = r.customer_sk AND s.year = r.year AND s.channel = r.channel
    LEFT JOIN customer_info c
        ON s.customer_sk = c.c_customer_sk
    LEFT JOIN category_year_avg cy
        ON s.category = cy.category AND s.year = cy.year
    INNER JOIN multi_channel_customers m
        ON s.customer_sk = m.customer_sk
    WHERE s.year BETWEEN 1999 AND 2002
),
final_result AS (
    SELECT
        customer_sk,
        year,
        channel,
        full_name,
        profit,
        return_amount,
        net_profit,
        profitability_flag,
        profit_rank,
        customer_code,
        ROUND(profit_vs_avg_ratio, 2) AS profit_vs_avg_ratio,
        first_sale_date,
        months_in_year
    FROM sales_with_returns
    WHERE profit_rank <= 5
)
SELECT *
FROM final_result
WHERE profitability_flag = 'PROFITABLE'
ORDER BY year DESC, net_profit DESC
LIMIT 50
