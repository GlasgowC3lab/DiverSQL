WITH
sales_union AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        d.d_year AS year,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_quantity AS quantity,
        ss.ss_ticket_number AS order_id,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
        AND d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_quantity AS quantity,
        cs.cs_order_number AS order_id,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
        AND d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_quantity AS quantity,
        ws.ws_order_number AS order_id,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
        AND d.d_year BETWEEN 2000 AND 2002
),

sales_agg AS (
    SELECT
        customer_sk,
        year,
        SUM(net_profit) AS total_net_profit,
        SUM(sales_amount) AS total_sales_amount,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(CASE WHEN channel = 'store' THEN net_profit ELSE 0 END) AS store_net_profit,
        SUM(CASE WHEN channel = 'store' THEN sales_amount ELSE 0 END) AS store_sales_amount,
        SUM(CASE WHEN channel = 'store' THEN quantity ELSE 0 END) AS store_quantity,
        SUM(CASE WHEN channel = 'store' THEN 1 ELSE 0 END) AS store_orders,
        SUM(CASE WHEN channel = 'catalog' THEN net_profit ELSE 0 END) AS catalog_net_profit,
        SUM(CASE WHEN channel = 'catalog' THEN sales_amount ELSE 0 END) AS catalog_sales_amount,
        SUM(CASE WHEN channel = 'catalog' THEN quantity ELSE 0 END) AS catalog_quantity,
        SUM(CASE WHEN channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_orders,
        SUM(CASE WHEN channel = 'web' THEN net_profit ELSE 0 END) AS web_net_profit,
        SUM(CASE WHEN channel = 'web' THEN sales_amount ELSE 0 END) AS web_sales_amount,
        SUM(CASE WHEN channel = 'web' THEN quantity ELSE 0 END) AS web_quantity,
        SUM(CASE WHEN channel = 'web' THEN 1 ELSE 0 END) AS web_orders
    FROM sales_union
    GROUP BY customer_sk, year
),

returns_union AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_year AS year,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_qty,
        sr.sr_return_amt AS return_amt,
        sr.sr_fee AS return_fee,
        sr.sr_return_ship_cost AS return_ship_cost,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_returned_date_sk IS NOT NULL
        AND d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        d.d_year AS year,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_qty,
        cr.cr_return_amount AS return_amt,
        cr.cr_fee AS return_fee,
        cr.cr_return_ship_cost AS return_ship_cost,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_returned_date_sk IS NOT NULL
        AND d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        d.d_year AS year,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_qty,
        wr.wr_return_amt AS return_amt,
        wr.wr_fee AS return_fee,
        wr.wr_return_ship_cost AS return_ship_cost,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE wr.wr_returned_date_sk IS NOT NULL
        AND d.d_year BETWEEN 2000 AND 2002
),

returns_agg AS (
    SELECT
        customer_sk,
        year,
        SUM(net_loss) AS total_net_loss,
        SUM(return_qty) AS total_return_qty,
        SUM(return_amt) AS total_return_amt,
        SUM(return_fee) AS total_return_fee,
        SUM(return_ship_cost) AS total_return_ship_cost,
        SUM(CASE WHEN channel = 'store' THEN net_loss ELSE 0 END) AS store_net_loss,
        SUM(CASE WHEN channel = 'catalog' THEN net_loss ELSE 0 END) AS catalog_net_loss,
        SUM(CASE WHEN channel = 'web' THEN net_loss ELSE 0 END) AS web_net_loss
    FROM returns_union
    GROUP BY customer_sk, year
),

customer_year AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        dy.d_year,
        COALESCE(sa.total_net_profit, 0) AS total_net_profit,
        COALESCE(sa.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(sa.total_quantity, 0) AS total_quantity,
        COALESCE(sa.total_orders, 0) AS total_orders,
        COALESCE(ra.total_net_loss, 0) AS total_net_loss,
        COALESCE(ra.total_return_amt, 0) AS total_return_amt,
        COALESCE(sa.store_net_profit, 0) AS store_net_profit,
        COALESCE(sa.catalog_net_profit, 0) AS catalog_net_profit,
        COALESCE(sa.web_net_profit, 0) AS web_net_profit,
        COALESCE(ra.store_net_loss, 0) AS store_net_loss,
        COALESCE(ra.catalog_net_loss, 0) AS catalog_net_loss,
        COALESCE(ra.web_net_loss, 0) AS web_net_loss,
        CASE 
            WHEN COALESCE(sa.store_net_profit, 0) > 0 THEN 'STORE_PROFIT'
            WHEN COALESCE(sa.catalog_net_profit, 0) > 0 THEN 'CATALOG_PROFIT'
            WHEN COALESCE(sa.web_net_profit, 0) > 0 THEN 'WEB_PROFIT'
            ELSE 'NO_PROFIT'
        END AS leading_profit_channel,
        ROW_NUMBER() OVER (PARTITION BY dy.d_year ORDER BY COALESCE(sa.total_net_profit, 0) DESC) AS net_profit_rank,
        CASE 
            WHEN COALESCE(sa.total_sales_amount, 0) > 0 THEN (COALESCE(sa.total_sales_amount, 0) - COALESCE(ra.total_return_amt, 0)) / COALESCE(sa.total_sales_amount, 0)
            ELSE NULL
        END AS net_sales_to_return_ratio,
        CASE 
            WHEN COALESCE(sa.total_orders, 0) > 0 THEN COALESCE(sa.total_net_profit, 0) / NULLIF(sa.total_orders, 0)
            ELSE NULL
        END AS profit_per_order,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(ra.store_net_loss, 0) + COALESCE(ra.catalog_net_loss, 0) + COALESCE(ra.web_net_loss, 0) AS total_loss_from_returns
    FROM
        customer c
        CROSS JOIN (SELECT DISTINCT d_year FROM date_dim WHERE d_year BETWEEN 2000 AND 2002) dy
        LEFT JOIN sales_agg sa ON c.c_customer_sk = sa.customer_sk AND dy.d_year = sa.year
        LEFT JOIN returns_agg ra ON c.c_customer_sk = ra.customer_sk AND dy.d_year = ra.year
),

final_agg AS (
    SELECT
        cy.c_customer_sk,
        cy.full_name,
        cy.d_year,
        cy.total_net_profit,
        cy.total_sales_amount,
        cy.total_quantity,
        cy.total_net_loss,
        cy.net_sales_to_return_ratio,
        cy.profit_per_order,
        cy.leading_profit_channel,
        cy.net_profit_rank,
        cy.total_loss_from_returns,
        CONCAT('Rank ', CAST(cy.net_profit_rank AS VARCHAR), ' in ', CAST(cy.d_year AS VARCHAR)) AS rank_label,
        (SELECT MAX(s.total_net_profit) FROM sales_agg s WHERE s.year = cy.d_year) AS max_year_profit,
        (SELECT AVG(s.total_net_profit / NULLIF(s.total_orders, 0)) FROM sales_agg s WHERE s.year = cy.d_year) AS avg_profit_per_order_year
    FROM customer_year cy
    WHERE cy.total_net_profit IS NOT NULL
)

SELECT
    fa.c_customer_sk,
    fa.full_name,
    fa.d_year,
    ROUND(fa.total_net_profit, 2) AS total_net_profit,
    ROUND(fa.total_sales_amount, 2) AS total_sales_amount,
    ROUND(fa.total_quantity, 0) AS total_quantity,
    ROUND(fa.total_net_loss, 2) AS total_net_loss,
    ROUND(fa.net_sales_to_return_ratio * 100, 2) AS net_sales_to_return_pct,
    ROUND(fa.profit_per_order, 2) AS profit_per_order,
    fa.leading_profit_channel,
    fa.net_profit_rank,
    ROUND(fa.total_loss_from_returns, 2) AS total_loss_from_returns,
    fa.rank_label,
    ROUND(fa.max_year_profit, 2) AS max_year_profit,
    ROUND(fa.avg_profit_per_order_year, 2) AS avg_profit_per_order_year
FROM final_agg fa
WHERE fa.net_profit_rank <= 10
ORDER BY fa.d_year, fa.net_profit_rank
