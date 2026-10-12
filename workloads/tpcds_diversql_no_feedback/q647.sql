WITH store_purchasers AS (
    SELECT ss.ss_customer_sk AS customer_sk,
           COUNT(*) AS purchase_cnt
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_radio = 'N'
      AND cd.cd_gender = 'M'
      AND ca.ca_state = 'CA'
    GROUP BY ss.ss_customer_sk
    HAVING COUNT(*) >= 5
),
return_customers AS (
    SELECT cr.cr_refunded_customer_sk AS customer_sk,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 100
      AND cd.cd_marital_status = 'M'
    GROUP BY cr.cr_refunded_customer_sk
    HAVING COUNT(*) >= 1
)
SELECT customer_sk
FROM store_purchasers
EXCEPT
SELECT customer_sk
FROM return_customers
ORDER BY customer_sk
