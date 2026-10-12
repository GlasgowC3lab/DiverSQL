WITH sampled_returns AS (
   SELECT *
   FROM catalog_returns
   TABLESAMPLE BERNOULLI (10)
   WHERE cr_return_amount > 0
     AND cr_return_quantity >= 1
),
filtered AS (
   SELECT
       sr.cr_order_number,
       sr.cr_return_amount,
       i.i_item_id,
       i.i_current_price,
       w.w_warehouse_name,
       w.w_state,
       cd.cd_gender,
       cd.cd_marital_status,
       cd.cd_dep_employed_count,
       hd.hd_buy_potential,
       p.p_promo_name,
       ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY sr.cr_return_amount DESC) AS rn_warehouse,
       RANK() OVER (PARTITION BY w.w_state ORDER BY sr.cr_return_amount DESC) AS rank_state
   FROM sampled_returns sr
   JOIN item i
     ON sr.cr_item_sk = i.i_item_sk
   JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w
     ON inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p
     ON p.p_item_sk = i.i_item_sk
   JOIN customer c
     ON sr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON sr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON sr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE i.i_current_price > 100
     AND w.w_state = 'CA'
     AND hd.hd_buy_potential = '>10000'
     AND cd.cd_marital_status = 'M'
     AND cd.cd_dep_employed_count >= 2
     AND p.p_discount_active = 'Y'
     AND sr.cr_order_number NOT IN (
         SELECT cr_order_number
         FROM catalog_returns
         WHERE cr_return_amount < 0
     )
)
SELECT
    cr_order_number,
    cr_return_amount,
    i_item_id,
    i_current_price,
    w_warehouse_name,
    w_state,
    cd_gender,
    cd_marital_status,
    cd_dep_employed_count,
    hd_buy_potential,
    p_promo_name,
    rank_state,
    rn_warehouse
FROM filtered
WHERE rn_warehouse <= 5
ORDER BY rank_state ASC, cr_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
