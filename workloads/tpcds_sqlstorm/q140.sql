WITH
sales_catalog AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        SUM(cs.cs_quantity) AS catalog_qty,
        COUNT(DISTINCT cs.cs_item_sk) AS catalog_items,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= (SELECT MAX(d2.d_year) - 1 FROM date_dim d2)
    GROUP BY c.c_customer_sk, ca.ca_state, d.d_year
),
sales_store AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        d.d_year,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        SUM(ss.ss_quantity) AS store_qty,
        COUNT(DISTINCT ss.ss_item_sk) AS store_items,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= (SELECT MAX(d2.d_year) - 1 FROM date_dim d2)
    GROUP BY c.c_customer_sk, ca.ca_state, d.d_year
),
sales_web AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        d.d_year,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(DISTINCT ws.ws_item_sk) AS web_items,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= (SELECT MAX(d2.d_year) - 1 FROM date_dim d2)
    GROUP BY c.c_customer_sk, ca.ca_state, d.d_year
),
returns AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        d.d_year,
        SUM(cr.cr_net_loss) AS catalog_loss,
        SUM(sr.sr_net_loss) AS store_loss,
        SUM(wr.wr_net_loss) AS web_loss
    FROM (
        SELECT cr_returned_date_sk, cr_returning_customer_sk, cr_net_loss
        FROM catalog_returns
    ) cr
    FULL OUTER JOIN (
        SELECT sr_returned_date_sk, sr_customer_sk, sr_net_loss
        FROM store_returns
    ) sr
        ON cr.cr_returning_customer_sk = sr.sr_customer_sk
    FULL OUTER JOIN (
        SELECT wr_returned_date_sk, wr_refunded_customer_sk, wr_net_loss
        FROM web_returns
    ) wr
        ON cr.cr_returning_customer_sk = wr.wr_refunded_customer_sk
    JOIN customer c ON COALESCE(cr.cr_returning_customer_sk, sr.sr_customer_sk, wr.wr_refunded_customer_sk) = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON COALESCE(cr.cr_returned_date_sk, sr.sr_returned_date_sk, wr.wr_returned_date_sk) = d.d_date_sk
    WHERE d.d_year >= (SELECT MAX(d2.d_year) - 1 FROM date_dim d2)
    GROUP BY c.c_customer_sk, ca.ca_state, d.d_year
)
SELECT
    COALESCE(sc.c_customer_sk, ss.c_customer_sk, sw.c_customer_sk) AS c_customer_sk,
    COALESCE(sc.ca_state, ss.ca_state, sw.ca_state) AS state,
    COALESCE(sc.d_year, ss.d_year, sw.d_year) AS year,
    COALESCE(sc.catalog_profit, 0) + COALESCE(ss.store_profit, 0) + COALESCE(sw.web_profit, 0) AS total_profit,
    COALESCE(sc.catalog_profit, 0) AS catalog_profit,
    COALESCE(ss.store_profit, 0) AS store_profit,
    COALESCE(sw.web_profit, 0) AS web_profit,
    COALESCE(r.catalog_loss, 0) + COALESCE(r.store_loss, 0) + COALESCE(r.web_loss, 0) AS total_loss,
    (COALESCE(sc.catalog_discount, 0) + COALESCE(ss.store_discount, 0) + COALESCE(sw.web_discount, 0))
        / NULLIF(COALESCE(sc.catalog_qty, 0) + COALESCE(ss.store_qty, 0) + COALESCE(sw.web_qty, 0), 0) AS avg_discount_per_unit,
    COALESCE(sc.catalog_qty, 0) + COALESCE(ss.store_qty, 0) + COALESCE(sw.web_qty, 0) AS total_units,
    COALESCE(sc.catalog_items, 0) + COALESCE(ss.store_items, 0) + COALESCE(sw.web_items, 0) AS distinct_items,
    COALESCE(sc.catalog_orders, 0) + COALESCE(ss.store_orders, 0) + COALESCE(sw.web_orders, 0) AS total_orders,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(sc.ca_state, ss.ca_state, sw.ca_state)
        ORDER BY (COALESCE(sc.catalog_profit, 0) + COALESCE(ss.store_profit, 0) + COALESCE(sw.web_profit, 0)
                  - COALESCE(r.catalog_loss, 0) - COALESCE(r.store_loss, 0) - COALESCE(r.web_loss, 0)) DESC
    ) AS state_rank
FROM sales_catalog sc
FULL OUTER JOIN sales_store ss
    ON sc.c_customer_sk = ss.c_customer_sk
   AND sc.ca_state = ss.ca_state
   AND sc.d_year = ss.d_year
FULL OUTER JOIN sales_web sw
    ON COALESCE(sc.c_customer_sk, ss.c_customer_sk) = sw.c_customer_sk
   AND COALESCE(sc.ca_state, ss.ca_state) = sw.ca_state
   AND COALESCE(sc.d_year, ss.d_year) = sw.d_year
FULL OUTER JOIN returns r
    ON COALESCE(sc.c_customer_sk, ss.c_customer_sk, sw.c_customer_sk) = r.c_customer_sk
   AND COALESCE(sc.ca_state, ss.ca_state, sw.ca_state) = r.ca_state
   AND COALESCE(sc.d_year, ss.d_year, sw.d_year) = r.d_year
WHERE (COALESCE(sc.catalog_profit, 0) + COALESCE(ss.store_profit, 0) + COALESCE(sw.web_profit, 0)
      - COALESCE(r.catalog_loss, 0) - COALESCE(r.store_loss, 0) - COALESCE(r.web_loss, 0)) > 0
ORDER BY total_profit DESC
FETCH FIRST 10 ROWS WITH TIES
