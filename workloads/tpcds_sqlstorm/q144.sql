WITH 
unified_sales AS (
    SELECT 
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        'web'
    FROM web_sales ws
),
unified_returns AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_amount AS return_amount,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        'store'
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_item_sk,
        wr.wr_return_amt,
        'web'
    FROM web_returns wr
),
sales_base AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        SUM(us.net_paid) AS total_net_paid,
        SUM(us.net_profit) AS total_net_profit,
        COUNT(DISTINCT us.customer_sk) AS distinct_customers,
        SUM(us.quantity) AS total_quantity
    FROM date_dim d
    LEFT JOIN unified_sales us ON us.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON i.i_item_sk = us.item_sk
    WHERE d.d_year = 2000
      AND us.channel IS NOT NULL
    GROUP BY d.d_date, i.i_item_sk, i.i_product_name, i.i_category, i.i_brand
),
sales_ranked AS (
    SELECT 
        sb.*,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS category_rank
    FROM sales_base sb
),
returns_agg AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        SUM(ur.return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM date_dim d
    LEFT JOIN unified_returns ur ON ur.returned_date_sk = d.d_date_sk
    LEFT JOIN item i ON i.i_item_sk = ur.item_sk
    WHERE d.d_year = 2000
      AND ur.channel IS NOT NULL
    GROUP BY d.d_date, i.i_item_sk
),
customer_item_spending AS (
    SELECT 
        us.item_sk AS i_item_sk,
        us.customer_sk,
        SUM(us.net_paid) AS total_spent
    FROM unified_sales us
    GROUP BY us.item_sk, us.customer_sk
),
top_customer_per_item AS (
    SELECT 
        i_item_sk,
        customer_sk,
        total_spent,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY total_spent DESC) AS rn
    FROM customer_item_spending
),
top_customer AS (
    SELECT i_item_sk, customer_sk
    FROM top_customer_per_item
    WHERE rn = 1
),
customer_tier AS (
    SELECT 
        c.c_customer_id,
        c.c_customer_sk,
        CASE 
            WHEN agg.total_spent > 10000 THEN 'Platinum'
            WHEN agg.total_spent > 5000 THEN 'Gold'
            WHEN agg.total_spent > 2000 THEN 'Silver'
            ELSE 'Bronze'
        END AS tier,
        agg.total_spent
    FROM (
        SELECT 
            us.customer_sk,
            SUM(us.net_paid) AS total_spent
        FROM unified_sales us
        GROUP BY us.customer_sk
    ) agg
    JOIN customer c ON c.c_customer_sk = agg.customer_sk
),
final AS (
    SELECT 
        sr.d_date,
        sr.i_category,
        sr.i_brand,
        CONCAT(sr.i_brand, ' - ', sr.i_product_name) AS product_desc,
        sr.total_net_paid,
        sr.total_net_profit,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN sr.total_net_paid > 0 THEN ROUND(COALESCE(ra.total_return_amount, 0) / sr.total_net_paid * 100, 2)
            ELSE 0
        END AS return_rate_pct,
        sr.distinct_customers,
        sr.total_quantity,
        sr.category_rank,
        ct.tier,
        CASE 
            WHEN ct.tier = 'Platinum' THEN 'VIP'
            WHEN ct.tier = 'Gold' THEN 'Preferred'
            ELSE 'Standard'
        END AS customer_segment,
        (sr.total_net_profit - COALESCE(ra.total_return_amount, 0)) AS net_contribution,
        (SELECT AVG(s2.total_net_paid) FROM sales_ranked s2 WHERE s2.i_category = sr.i_category) AS avg_category_net_paid,
        (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2000 AND d2.d_moy = EXTRACT(month FROM sr.d_date)) AS same_month_last_day,
        ct.total_spent AS top_customer_total_spent
    FROM sales_ranked sr
    LEFT JOIN returns_agg ra ON ra.d_date = sr.d_date AND ra.i_item_sk = sr.i_item_sk
    LEFT JOIN top_customer tcust ON tcust.i_item_sk = sr.i_item_sk
    LEFT JOIN customer_tier ct ON ct.c_customer_sk = tcust.customer_sk
    WHERE (sr.total_net_paid > 1000 OR sr.distinct_customers > 10)
      AND (sr.category_rank <= 5 OR sr.category_rank IS NULL)
)
SELECT
    d_date,
    i_category,
    i_brand,
    product_desc,
    total_net_paid,
    total_net_profit,
    net_contribution,
    distinct_customers,
    total_quantity,
    return_rate_pct,
    avg_category_net_paid,
    same_month_last_day,
    customer_segment,
    tier,
    top_customer_total_spent
FROM final
ORDER BY total_net_paid DESC
LIMIT 100
