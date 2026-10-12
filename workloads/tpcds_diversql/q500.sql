WITH
  full_join AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_store_sk,
      sr.sr_return_amt,
      sr.sr_return_tax,
      sr.sr_return_amt_inc_tax,
      sr.sr_fee,
      sr.sr_net_loss,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      ca.ca_state,
      ca.ca_county,
      s.s_store_name,
      s.s_state AS store_state,
      s.s_city  AS store_city
    FROM store_returns sr
    FULL OUTER JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
      sr.sr_return_amt > 10                                 -- predicate 1
      AND sr.sr_return_tax < 5                              -- predicate 2
      AND i.i_current_price BETWEEN 5 AND 500               -- predicate 3
      AND hd.hd_vehicle_count >= 1                         -- predicate 4
      AND ca.ca_state = 'TX'                               -- predicate 5
      AND s.s_store_name IS NOT NULL                        -- predicate 6
  ),

  promo_items AS (
    SELECT
      p.p_promo_id,
      i.i_item_sk,
      i.i_category,
      i.i_brand,
      p.p_discount_active,
      CASE WHEN p.p_channel_radio = 'Y' THEN 1 ELSE 0 END AS radio_channel_flag
    FROM promotion p
    JOIN item i
      ON p.p_item_sk = i.i_item_sk
    WHERE
      p.p_discount_active = 'Y'            -- predicate 7
      AND p.p_purpose <> 'Unknown'          -- predicate 8
      AND p.p_channel_demo = 'N'            -- predicate 9
  ),

  union_set AS (
    SELECT
      fj.sr_returned_date_sk,
      fj.sr_item_sk,
      fj.i_category,
      fj.i_brand,
      fj.sr_return_amt,
      fj.sr_net_loss,
      pi.radio_channel_flag
    FROM full_join fj
    JOIN promo_items pi
      ON fj.sr_item_sk = pi.i_item_sk
    WHERE fj.sr_return_amt_inc_tax > 50                     -- predicate 10

    UNION

    SELECT
      fj.sr_returned_date_sk,
      fj.sr_item_sk,
      fj.i_category,
      fj.i_brand,
      fj.sr_return_amt,
      fj.sr_net_loss,
      0 AS radio_channel_flag
    FROM full_join fj
    WHERE fj.sr_return_amt_inc_tax <= 50
  ),

  intersect_set AS (
    SELECT sr_item_sk FROM (
      SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 1   -- predicate 11
    )
    INTERSECT
    SELECT i_item_sk FROM item WHERE i_current_price > 20                  -- predicate 12
  ),

  final AS (
    SELECT
      us.sr_returned_date_sk,
      us.sr_item_sk,
      us.i_category,
      us.i_brand,
      us.sr_return_amt,
      us.sr_net_loss,
      us.radio_channel_flag,
      ROW_NUMBER() OVER (ORDER BY us.sr_return_amt DESC) AS global_row_num,
      RANK() OVER (PARTITION BY us.i_category ORDER BY us.sr_net_loss ASC) AS category_net_loss_rank,
      CASE WHEN us.sr_net_loss > 0 THEN 'LOSS' ELSE 'PROFIT' END AS loss_indicator
    FROM union_set us
    WHERE us.sr_item_sk IN (SELECT sr_item_sk FROM intersect_set)
  )

SELECT
  final.sr_returned_date_sk,
  final.sr_item_sk,
  final.i_category,
  final.i_brand,
  final.sr_return_amt,
  final.sr_net_loss,
  final.radio_channel_flag,
  final.global_row_num,
  final.category_net_loss_rank,
  final.loss_indicator
FROM final
ORDER BY final.global_row_num
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
