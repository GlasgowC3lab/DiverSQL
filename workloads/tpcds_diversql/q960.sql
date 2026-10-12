WITH
  /* Items whose product name contains the word "Pro" and extracts a code prefix */
  item_match AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      regexp_extract(i.i_product_name, '([A-Z]{2,})', 1) AS prod_code,
      length(i.i_product_name) AS name_len
    FROM item i
    WHERE regexp_like(i.i_product_name, 'Pro')
  ),

  /* Aggregate store return net loss per item */
  store_ret_agg AS (
    SELECT
      sr.sr_item_sk,
      SUM(sr.sr_net_loss) AS total_return_loss,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
  ),

  /* Full outer join the aggregated returns with the filtered items */
  full_join AS (
    SELECT
      COALESCE(sra.sr_item_sk, im.i_item_sk) AS item_sk,
      sra.total_return_loss,
      sra.return_cnt,
      im.i_product_name,
      im.prod_code,
      im.name_len
    FROM store_ret_agg sra
    FULL OUTER JOIN item_match im
      ON sra.sr_item_sk = im.i_item_sk
  ),

  /* Order numbers present in catalog returns but not in web returns */
  orders_diff AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    EXCEPT
    SELECT wr.wr_order_number
    FROM web_returns wr
  )

SELECT
  fj.item_sk,
  fj.i_product_name,
  fj.prod_code,
  fj.name_len,
  COALESCE(fj.total_return_loss, 0) AS total_return_loss,
  COALESCE(fj.return_cnt, 0) AS return_cnt,
  (SELECT COUNT(*) FROM orders_diff) AS missing_order_cnt
FROM full_join fj
WHERE fj.i_product_name LIKE '%Pro%'
  AND fj.i_product_name NOT LIKE '%Test%'
ORDER BY fj.total_return_loss DESC NULLS LAST
OFFSET 0 FETCH FIRST 100 ROWS ONLY
