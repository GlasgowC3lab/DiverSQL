WITH sales_agg AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        SUM(CASE WHEN sr.sr_return_quantity IS NOT NULL THEN sr.sr_return_quantity ELSE 0 END) AS store_returns_qty
    FROM store_sales ss
    LEFT JOIN store_returns sr 
        ON ss.ss_ticket_number = sr.sr_ticket_number 
        AND ss.ss_store_sk = sr.sr_store_sk 
        AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
    INNER JOIN customer c 
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN date_dim d 
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND (c.c_preferred_cust_flag = 'Y' OR c.c_birth_year BETWEEN 1960 AND 1970)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
web_sales_agg AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        d.d_year,
        SUM(ws.ws_net_paid) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_txns,
        SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_quantity ELSE 0 END) AS web_returns_qty
    FROM web_sales ws
    LEFT JOIN web_returns wr 
        ON ws.ws_order_number = wr.wr_order_number 
        AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
    INNER JOIN customer c 
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN date_dim d 
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND (c.c_preferred_cust_flag = 'Y' OR c.c_birth_year BETWEEN 1960 AND 1970)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
combined AS (
    SELECT 
        ca.c_customer_sk,
        ca.customer_name,
        ca.d_year,
        ca.store_sales,
        ca.store_profit,
        ca.store_txns,
        ca.store_returns_qty,
        COALESCE(wa.web_sales, 0) AS web_sales,
        COALESCE(wa.web_profit, 0) AS web_profit,
        COALESCE(wa.web_txns, 0) AS web_txns,
        COALESCE(wa.web_returns_qty, 0) AS web_returns_qty,
        (ca.store_sales + COALESCE(wa.web_sales,0)) AS total_sales,
        (ca.store_profit + COALESCE(wa.web_profit,0)) AS total_profit,
        (ca.store_returns_qty + COALESCE(wa.web_returns_qty,0)) AS total_returns_qty
    FROM sales_agg ca
    LEFT JOIN web_sales_agg wa
        ON ca.c_customer_sk = wa.c_customer_sk AND ca.d_year = wa.d_year
),
ranked AS (
    SELECT 
        rs.c_customer_sk,
        rs.customer_name,
        rs.d_year,
        rs.total_sales,
        rs.total_profit,
        rs.total_returns_qty,
        ROW_NUMBER() OVER (PARTITION BY rs.d_year ORDER BY rs.total_profit DESC) AS profit_rank,
        (SELECT SUM(ss2.ss_net_profit)
         FROM store_sales ss2
         INNER JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
         WHERE ss2.ss_customer_sk = rs.c_customer_sk
           AND d2.d_year = rs.d_year - 1) AS prior_year_profit
    FROM combined rs
),
top_union AS (
    SELECT 
        r.c_customer_sk,
        r.customer_name,
        r.d_year,
        r.total_sales,
        r.total_profit,
        r.total_returns_qty,
        r.profit_rank,
        r.prior_year_profit,
        CASE 
            WHEN r.prior_year_profit IS NULL THEN NULL
            WHEN r.prior_year_profit = 0 THEN NULL
            ELSE (r.total_profit - r.prior_year_profit) / r.prior_year_profit
        END AS profit_growth_ratio,
        COALESCE(NULLIF(r.total_sales,0),0) AS sales_nonzero
    FROM ranked r
    WHERE r.profit_rank <= 10
    UNION ALL
    SELECT 
        NULL,
        'TOTAL',
        NULL,
        SUM(total_sales),
        SUM(total_profit),
        SUM(total_returns_qty),
        NULL,
        NULL,
        NULL,
        NULL
    FROM ranked
    WHERE profit_rank <= 10
)
SELECT 
    c_customer_sk,
    customer_name,
    d_year,
    total_sales,
    total_profit,
    total_returns_qty,
    profit_rank,
    prior_year_profit,
    profit_growth_ratio,
    sales_nonzero,
    LAG(total_profit) OVER (ORDER BY total_profit DESC) AS prev_total_profit
FROM top_union
ORDER BY total_profit DESC
LIMIT 20
