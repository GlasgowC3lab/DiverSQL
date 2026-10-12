WITH sales_union AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_sold_date_sk AS sale_date_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim)
    UNION ALL
    SELECT ss.ss_customer_sk,
           ss.ss_net_profit,
           ss.ss_sold_date_sk,
           'store'
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim)
    UNION ALL
    SELECT ws.ws_bill_customer_sk,
           ws.ws_net_profit,
           ws.ws_sold_date_sk,
           'web'
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim)
),
customer_sales AS (
    SELECT customer_sk,
           SUM(net_profit) AS total_net_profit,
           COUNT(*) AS txn_count,
           MAX(sale_date_sk) AS latest_sale_date_sk,
           COUNT(DISTINCT channel) AS channel_count
    FROM sales_union
    GROUP BY customer_sk
),
customer_details AS (
    SELECT c.c_customer_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           c.c_email_address,
           cd.cd_gender,
           hd.hd_income_band_sk,
           c.c_birth_year
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
final AS (
    SELECT 
        cs.customer_sk,
        cs.total_net_profit,
        cs.txn_count,
        cs.channel_count,
        cs.latest_sale_date_sk,
        cd.full_name,
        cd.c_email_address,
        cd.cd_gender,
        CASE 
            WHEN cs.total_net_profit > 200000 THEN 'Platinum'
            WHEN cs.total_net_profit > 100000 THEN 'Gold'
            WHEN cs.total_net_profit > 50000 THEN 'Silver'
            ELSE 'Bronze'
        END AS tier,
        ROUND(cs.total_net_profit / NULLIF(cs.txn_count, 0), 2) AS avg_profit_per_txn,
        d.d_date AS latest_sale_date,
        CASE 
            WHEN d.d_date >= DATE '2023-01-01' THEN 'Active' 
            ELSE 'Inactive' 
        END AS activity_status,
        COALESCE(CAST(cd.hd_income_band_sk AS VARCHAR), 'UNKNOWN') AS income_band,
        cd.c_birth_year,
        (SELECT MAX(p.p_cost) FROM promotion p WHERE p.p_start_date_sk <= cs.latest_sale_date_sk) AS max_promo_cost
    FROM customer_sales cs
    LEFT JOIN customer_details cd ON cs.customer_sk = cd.c_customer_sk
    LEFT JOIN date_dim d ON cs.latest_sale_date_sk = d.d_date_sk
),
ranked AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
        full_name,
        c_email_address,
        total_net_profit,
        txn_count,
        channel_count,
        avg_profit_per_txn,
        tier,
        CAST(latest_sale_date AS VARCHAR) AS latest_sale_date,
        activity_status,
        cd_gender,
        income_band,
        c_birth_year,
        max_promo_cost,
        ROUND(total_net_profit / NULLIF(max_promo_cost, 0), 2) AS profit_per_promo_cost
    FROM final
)
SELECT 
    profit_rank,
    full_name,
    c_email_address,
    total_net_profit,
    txn_count,
    channel_count,
    avg_profit_per_txn,
    tier,
    latest_sale_date,
    activity_status,
    cd_gender,
    income_band,
    c_birth_year,
    max_promo_cost,
    profit_per_promo_cost
FROM ranked
WHERE profit_rank <= 100
ORDER BY profit_rank
