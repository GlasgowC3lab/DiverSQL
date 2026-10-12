WITH sales_agg AS (
    SELECT ss_customer_sk,
           ss_promo_sk,
           SUM(ss_ext_sales_price) AS total_sales,
           SUM(ss_net_paid_inc_tax) AS total_paid,
           COUNT(*) AS txn_count
    FROM store_sales
    WHERE ss_ext_sales_price > 500
      AND ss_quantity >= 2
    GROUP BY ss_customer_sk, ss_promo_sk
),
promo_set AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_cost > 1000
      AND p_response_target = 1
),
promo_excl AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_channel_press = 'Y'
)
SELECT
    c.c_customer_id,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    p.p_promo_name,
    sa.total_sales,
    sa.total_paid,
    sa.txn_count,
    (
        SELECT COUNT(*)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
    ) AS total_transactions_for_customer
FROM sales_agg sa
JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE p.p_promo_sk IN (
        SELECT p_promo_sk FROM promo_set
        EXCEPT
        SELECT p_promo_sk FROM promo_excl
    )
  AND ca.ca_state IN ('CA', 'TX', 'NY')
  AND hd.hd_buy_potential = '5001-10000'
  AND cd.cd_education_status = 'College'
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    p.p_promo_name,
    sa.total_sales,
    sa.total_paid,
    sa.txn_count,
    c.c_customer_sk
ORDER BY sa.total_sales DESC
LIMIT 100
