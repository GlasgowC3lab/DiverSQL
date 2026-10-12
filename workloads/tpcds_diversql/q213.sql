WITH sr_agg AS (
    SELECT
        sr_item_sk,
        sr_reason_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    WHERE sr_return_tax > 5.00
      AND sr_reversed_charge < 100.00
    GROUP BY sr_item_sk, sr_reason_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    cs.cs_order_number,
    cs.cs_net_profit,
    sr_agg.total_return_qty,
    sr_agg.total_return_amt,
    RANK() OVER (PARTITION BY i.i_item_id ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    CASE
        WHEN cs.cs_coupon_amt > 1000.00 THEN 'High Coupon'
        WHEN cs.cs_coupon_amt BETWEEN 100.00 AND 1000.00 THEN 'Medium Coupon'
        ELSE 'Low Coupon'
    END AS coupon_category
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN sr_agg ON i.i_item_sk = sr_agg.sr_item_sk
JOIN reason r ON sr_agg.sr_reason_sk = r.r_reason_sk
WHERE cs.cs_wholesale_cost BETWEEN 20.00 AND 80.00
  AND cs.cs_ext_discount_amt > 20.00
  AND i.i_brand_id IN (1, 2)
  AND r.r_reason_id LIKE 'AAAAAAA%'
  AND EXISTS (
        SELECT 1 FROM store_returns sr_check
        WHERE sr_check.sr_item_sk = cs.cs_item_sk
          AND sr_check.sr_net_loss > 0.00
    )
ORDER BY profit_rank ASC, cs.cs_order_number DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
