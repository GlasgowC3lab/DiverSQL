WITH date_lookup AS (
    SELECT d_date_sk,
           d_year,
           d_quarter_seq
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 2002
),
customer_core AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
           (year(DATE '2024-10-01') - c.c_birth_year) AS age,
           CASE 
               WHEN cd.cd_gender = 'M' THEN 1
               WHEN cd.cd_gender = 'F' THEN 2
               ELSE 0
           END AS gender_code,
           CONCAT(UPPER(substr(c.c_first_name,1,1)), LOWER(c.c_last_name)) AS name_key,
           COALESCE(cd.cd_credit_rating,'UNKNOWN') AS credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk IS NOT NULL
),
sales_union AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS cust_sk,
        ss.ss_store_sk AS loc_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_coupon_amt AS coupon,
        COALESCE(ss.ss_net_paid, 0) AS net_paid_coalesce,
        COALESCE(ss.ss_store_sk, -1) AS loc_normalized
    FROM store_sales ss
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        COALESCE(ws.ws_net_paid, 0),
        COALESCE(ws.ws_web_site_sk, -1)
    FROM web_sales ws
    UNION ALL
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        COALESCE(cs.cs_net_paid, 0),
        COALESCE(cs.cs_call_center_sk, -1)
    FROM catalog_sales cs
),
ranked_sales AS (
    SELECT
        su.*,
        d.d_year,
        d.d_quarter_seq,
        ROW_NUMBER() OVER (PARTITION BY su.cust_sk, su.channel ORDER BY su.net_paid DESC) AS rn_by_cust_chan,
        SUM(su.net_paid) OVER (PARTITION BY su.channel, d.d_year) AS total_net_by_chan_year,
        SUM(su.net_profit) OVER (PARTITION BY su.channel) AS total_profit_by_chan,
        CASE 
            WHEN su.net_paid > 0 THEN 'POSITIVE'
            WHEN su.net_paid < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS net_sign,
        COALESCE(su.coupon, 0) * 1.0 / NULLIF(su.net_paid, 0) AS coupon_rate
    FROM sales_union su
    LEFT JOIN date_lookup d
      ON su.date_sk = d.d_date_sk
    WHERE su.net_paid IS NOT NULL
),
customer_agg AS (
    SELECT
        rs.cust_sk,
        COUNT(*) AS trans_count,
        SUM(CASE WHEN rs.net_paid > 0 THEN rs.net_paid ELSE 0 END) AS total_spent,
        MAX(rs.net_paid) AS max_spent,
        MIN(rs.net_paid) AS min_spent,
        APPROX_PERCENTILE(rs.coupon_rate, 0.5) AS median_coupon_rate
    FROM ranked_sales rs
    JOIN customer_core cc
      ON rs.cust_sk = cc.c_customer_sk
    GROUP BY rs.cust_sk
    HAVING COUNT(*) > 5
),
top_customers AS (
    SELECT cust_sk
    FROM (
        SELECT ca.cust_sk,
               ca.total_spent,
               ROW_NUMBER() OVER (ORDER BY ca.total_spent DESC) AS rn
        FROM customer_agg ca
    ) t
    WHERE rn <= 10
),
final AS (
    SELECT
        rs.channel,
        rs.d_year,
        rs.d_quarter_seq,
        rs.item_sk,
        i.i_product_name,
        rs.cust_sk,
        cc.name_key,
        rs.net_paid,
        rs.net_profit,
        rs.net_sign,
        rs.coupon_rate,
        rs.loc_normalized,
        CASE 
            WHEN rs.channel = 'store' AND rs.loc_sk IS NULL THEN 'UNKNOWN_STORE'
            WHEN rs.channel = 'web' AND rs.loc_sk IS NULL THEN 'UNKNOWN_SITE'
            WHEN rs.channel = 'catalog' AND rs.loc_sk IS NULL THEN 'UNKNOWN_CALL_CENTER'
            ELSE 'KNOWN'
        END AS loc_status,
        LPAD(REVERSE(cc.name_key), 10, 'X') AS rev_name_key_padded,
        REGEXP_EXTRACT(CAST(rs.loc_sk AS VARCHAR), '(\\d+)', 1) AS loc_sk_digits,
        COALESCE((SELECT median_coupon_rate FROM customer_agg ca WHERE ca.cust_sk = rs.cust_sk), 0.0) AS cust_median_coupon,
        (SELECT COUNT(*) 
         FROM ranked_sales rs2 
         WHERE rs2.channel = rs.channel 
           AND rs2.d_year = rs.d_year 
           AND rs2.net_paid > rs.net_paid) + 1 AS rank_within_chan_year,
        rs.total_profit_by_chan
    FROM ranked_sales rs
    LEFT JOIN item i
      ON rs.item_sk = i.i_item_sk
    LEFT JOIN customer_core cc
      ON rs.cust_sk = cc.c_customer_sk
    WHERE rs.rn_by_cust_chan = 1
      AND rs.net_sign = 'POSITIVE'
      AND rs.coupon_rate > 0.05
      AND rs.total_net_by_chan_year > 10000
      AND (rs.loc_normalized <> -1 OR rs.loc_normalized IS NULL)
      AND rs.cust_sk IN (SELECT cust_sk FROM top_customers)
)
SELECT *
FROM final
WHERE rev_name_key_padded LIKE '%A%'
ORDER BY channel, d_year DESC, total_profit_by_chan DESC
