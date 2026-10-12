WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date >= date_add('year', -2, DATE '2024-10-01')
),
sales_union AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS ext_sales_price,
           'catalog' AS channel
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)
    UNION ALL
    SELECT ss.ss_customer_sk AS customer_sk,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_quantity AS quantity,
           ss.ss_ext_sales_price AS ext_sales_price,
           'store' AS channel
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_quantity AS quantity,
           ws.ws_ext_sales_price AS ext_sales_price,
           'web' AS channel
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)
),
aggregated_customers AS (
    SELECT 
        cu.c_customer_sk,
        COALESCE(cu.c_first_name, '') || ' ' || COALESCE(cu.c_last_name, '') AS full_name,
        COUNT(su.customer_sk) AS total_orders,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.net_profit) AS total_net_profit,
        AVG(su.net_paid) AS avg_net_paid,
        MAX(su.net_paid) AS max_order_value,
        SUM(CASE WHEN su.channel = 'store' THEN su.net_paid ELSE 0 END) AS store_net_paid,
        SUM(CASE WHEN su.channel = 'web' THEN su.net_paid ELSE 0 END) AS web_net_paid,
        SUM(CASE WHEN su.channel = 'catalog' THEN su.net_paid ELSE 0 END) AS catalog_net_paid
    FROM customer cu
    LEFT JOIN sales_union su
        ON cu.c_customer_sk = su.customer_sk
    GROUP BY cu.c_customer_sk, cu.c_first_name, cu.c_last_name
),
ranked_customers AS (
    SELECT 
        ac.*,
        ROW_NUMBER() OVER (ORDER BY ac.total_net_paid DESC) AS sales_rank
    FROM aggregated_customers ac
),
customer_latest_purchase AS (
    SELECT 
        cu.c_customer_sk,
        MAX(su.date_sk) AS last_purchase_date_sk
    FROM customer cu
    LEFT JOIN sales_union su
        ON cu.c_customer_sk = su.customer_sk
    GROUP BY cu.c_customer_sk
),
last_purchase_date AS (
    SELECT 
        clp.c_customer_sk,
        d.d_date AS last_purchase_date,
        CASE 
            WHEN d.d_date IS NULL THEN 'No Purchases'
            WHEN d.d_year = year(DATE '2024-10-01') THEN 'This Year'
            WHEN d.d_year = year(DATE '2024-10-01') - 1 THEN 'Last Year'
            ELSE 'Earlier'
        END AS purchase_period
    FROM customer_latest_purchase clp
    LEFT JOIN date_dim d
        ON clp.last_purchase_date_sk = d.d_date_sk
    GROUP BY clp.c_customer_sk, d.d_date, d.d_year
),
demographics_join AS (
    SELECT 
        cu.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer cu
    LEFT JOIN customer_demographics cd 
        ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cu.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
combined AS (
    SELECT 
        rc.c_customer_sk,
        rc.full_name,
        rc.total_orders,
        rc.total_net_paid,
        rc.total_net_profit,
        rc.avg_net_paid,
        rc.max_order_value,
        rc.store_net_paid,
        rc.web_net_paid,
        rc.catalog_net_paid,
        rc.sales_rank,
        lpd.last_purchase_date,
        lpd.purchase_period,
        dj.cd_gender,
        dj.cd_marital_status,
        dj.cd_education_status,
        dj.ib_lower_bound,
        dj.ib_upper_bound,
        CASE 
            WHEN rc.total_net_paid = 0 THEN NULL
            ELSE round(rc.total_net_profit / rc.total_net_paid, 4)
        END AS profit_margin,
        CASE 
            WHEN rc.total_net_paid > 50000 THEN 'VIP'
            WHEN rc.total_net_paid > 20000 THEN 'Gold'
            WHEN rc.total_net_paid > 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier,
        COALESCE(
            CAST(dj.ib_lower_bound AS varchar) || '-' || CAST(dj.ib_upper_bound AS varchar),
            'Unknown'
        ) AS income_bracket
    FROM ranked_customers rc
    LEFT JOIN last_purchase_date lpd
        ON rc.c_customer_sk = lpd.c_customer_sk
    LEFT JOIN demographics_join dj
        ON rc.c_customer_sk = dj.c_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.full_name,
    c.total_orders,
    c.total_net_paid,
    c.total_net_profit,
    c.avg_net_paid,
    c.max_order_value,
    c.store_net_paid,
    c.web_net_paid,
    c.catalog_net_paid,
    c.sales_rank,
    c.last_purchase_date,
    c.purchase_period,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.ib_lower_bound,
    c.ib_upper_bound,
    c.profit_margin,
    c.customer_tier,
    c.income_bracket,
    (SELECT COALESCE(SUM(sr.sr_return_amt), 0) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS total_store_return_amount,
    (SELECT COALESCE(SUM(wr.wr_return_amt), 0) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = c.c_customer_sk) AS total_web_return_amount
FROM combined c
WHERE 
    (c.customer_tier = 'VIP' OR c.profit_margin > 0.2)
    AND (c.purchase_period = 'This Year' OR c.purchase_period = 'Last Year')
ORDER BY c.sales_rank
LIMIT 100
