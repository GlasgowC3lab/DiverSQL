WITH
    all_sales AS (
        SELECT ss.ss_customer_sk AS customer_sk,
               ss.ss_item_sk AS item_sk,
               ss.ss_quantity AS qty,
               ss.ss_net_paid AS net_paid,
               ss.ss_ext_discount_amt AS discount_amt,
               d.d_date AS sale_date
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        UNION ALL
        SELECT ws.ws_bill_customer_sk AS customer_sk,
               ws.ws_item_sk AS item_sk,
               ws.ws_quantity AS qty,
               ws.ws_net_paid AS net_paid,
               ws.ws_ext_discount_amt AS discount_amt,
               d.d_date AS sale_date
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        UNION ALL
        SELECT cs.cs_bill_customer_sk AS customer_sk,
               cs.cs_item_sk AS item_sk,
               cs.cs_quantity AS qty,
               cs.cs_net_paid AS net_paid,
               cs.cs_ext_discount_amt AS discount_amt,
               d.d_date AS sale_date
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    sales_agg AS (
        SELECT
            customer_sk,
            SUM(net_paid) AS total_net_paid,
            SUM(discount_amt) AS total_discount,
            COUNT(*) AS total_txns,
            MAX(sale_date) AS last_purchase_date
        FROM all_sales
        GROUP BY customer_sk
    ),
    top_item_per_customer AS (
        SELECT
            customer_sk,
            item_sk,
            total_qty,
            ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_qty DESC) AS rn
        FROM (
            SELECT
                customer_sk,
                item_sk,
                SUM(qty) AS total_qty
            FROM all_sales
            GROUP BY customer_sk, item_sk
        ) t
    ),
    returns_agg AS (
        SELECT sr_customer_sk AS customer_sk,
               SUM(sr_net_loss) AS total_loss
        FROM store_returns
        GROUP BY sr_customer_sk
        UNION ALL
        SELECT wr_refunded_customer_sk AS customer_sk,
               SUM(wr_net_loss) AS total_loss
        FROM web_returns
        GROUP BY wr_refunded_customer_sk
        UNION ALL
        SELECT cr_refunded_customer_sk AS customer_sk,
               SUM(cr_net_loss) AS total_loss
        FROM catalog_returns
        GROUP BY cr_refunded_customer_sk
    ),
    customer_losses AS (
        SELECT
            customer_sk,
            SUM(total_loss) AS total_loss
        FROM returns_agg
        GROUP BY customer_sk
    ),
    customer_profile AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
            COALESCE(hd.hd_income_band_sk, -1) AS income_band,
            ca.ca_state,
            ca.ca_country,
            CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END AS preferred_flag
        FROM customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    ),
    combined AS (
        SELECT
            cp.c_customer_sk AS c_customer_sk,
            cp.c_first_name,
            cp.c_last_name,
            cp.gender,
            cp.income_band,
            cp.ca_state,
            cp.ca_country,
            COALESCE(sa.total_net_paid, 0) AS total_net_paid,
            COALESCE(sa.total_discount, 0) AS total_discount,
            COALESCE(sa.total_txns, 0) AS total_txns,
            COALESCE(sa.last_purchase_date, DATE '1900-01-01') AS last_purchase_date,
            COALESCE(cl.total_loss, 0) AS total_loss,
            (COALESCE(sa.total_net_paid, 0) - COALESCE(cl.total_loss, 0)) AS net_profit_after_loss,
            (SELECT COUNT(DISTINCT a2.sale_date)
             FROM all_sales a2
             WHERE a2.customer_sk = cp.c_customer_sk) AS distinct_purchase_days,
            ti.item_sk,
            i.i_product_name,
            ti.total_qty AS top_item_qty,
            cp.preferred_flag
        FROM customer_profile cp
        LEFT JOIN sales_agg sa ON cp.c_customer_sk = sa.customer_sk
        LEFT JOIN customer_losses cl ON cp.c_customer_sk = cl.customer_sk
        LEFT JOIN (
            SELECT
                tic.customer_sk,
                tic.item_sk,
                tic.total_qty
            FROM top_item_per_customer tic
            WHERE tic.rn = 1
        ) ti ON cp.c_customer_sk = ti.customer_sk
        LEFT JOIN item i ON ti.item_sk = i.i_item_sk
    ),
    ranked AS (
        SELECT
            *,
            ROW_NUMBER() OVER (ORDER BY net_profit_after_loss DESC) AS rn,
            COUNT(*) OVER () AS total_customers
        FROM combined
        WHERE net_profit_after_loss > 0
    )
SELECT
    rn,
    total_customers,
    c_customer_sk,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    gender,
    income_band,
    ca_state,
    ca_country,
    total_net_paid,
    total_discount,
    total_txns,
    total_loss,
    net_profit_after_loss,
    last_purchase_date,
    CASE WHEN last_purchase_date >= DATE '2001-12-01' THEN 'RECENT' ELSE 'OLDER' END AS recent_flag,
    i_product_name AS top_product,
    top_item_qty,
    distinct_purchase_days,
    preferred_flag
FROM ranked
WHERE rn <= 10
ORDER BY net_profit_after_loss DESC
