/* goal: Identify the top profitable sales and return transactions per customer birth country, combine them, rank the top 5 per country, attach each customer's total net profit from all sales, and cross‑join a tiny dimension of three static values. */
WITH sales_data AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_birth_country AS birth_country,
        i.i_category AS category,
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS profit,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS amount,
        p.p_promo_name AS promo_name
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_category_id IN (4, 7)
      AND c.c_birth_country IN ('CHILE', 'MEXICO')
      AND cs.cs_quantity > 0
),
returns_data AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_birth_country AS birth_country,
        i.i_category AS category,
        wr.wr_order_number AS order_number,
        -wr.wr_net_loss AS profit,
        wr.wr_return_quantity AS quantity,
        wr.wr_return_amt AS amount,
        r.r_reason_desc AS promo_name
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_category_id IN (4, 7)
      AND c.c_birth_country IN ('CHILE', 'MEXICO')
      AND wr.wr_return_quantity > 0
),
combined AS (
    SELECT
        customer_sk,
        birth_country,
        category,
        order_number,
        profit,
        quantity,
        amount,
        promo_name
    FROM sales_data
    UNION ALL
    SELECT
        customer_sk,
        birth_country,
        category,
        order_number,
        profit,
        quantity,
        amount,
        promo_name
    FROM returns_data
)
SELECT
    comb.customer_sk,
    comb.birth_country,
    comb.category,
    comb.order_number,
    comb.profit,
    comb.quantity,
    comb.amount,
    comb.promo_name,
    lp.total_profit,
    dim.dim_val,
    comb.rn
FROM (
    SELECT
        combined.*,
        ROW_NUMBER() OVER (PARTITION BY birth_country ORDER BY profit DESC) AS rn
    FROM combined
) comb
CROSS JOIN (
    SELECT 1 AS dim_val UNION ALL SELECT 2 UNION ALL SELECT 3
) dim
LEFT JOIN LATERAL (
    SELECT SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    WHERE cs.cs_bill_customer_sk = comb.customer_sk
) lp ON TRUE
WHERE comb.rn <= 5
ORDER BY comb.birth_country, comb.profit DESC
LIMIT 100
