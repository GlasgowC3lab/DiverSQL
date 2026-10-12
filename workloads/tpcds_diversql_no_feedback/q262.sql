WITH sales_agg AS (
  SELECT
    cs.cs_item_sk AS item_sk,
    i.i_item_desc,
    i.i_brand,
    i.i_item_id,
    ca.ca_zip,
    SUBSTR(ca.ca_zip, 1, 2) AS zip_prefix,
    CONCAT(i.i_brand, '-', i.i_item_id) AS brand_item_code,
    REGEXP_EXTRACT(i.i_item_desc, '([0-9]{2})', 1) AS desc_number,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE REGEXP_LIKE(i.i_item_desc, '[A-Za-z]{3}[0-9]{2}')
    AND ca.ca_zip LIKE '9%'
  GROUP BY cs.cs_item_sk, i.i_item_desc, i.i_brand, i.i_item_id, ca.ca_zip
),
returns_agg AS (
  SELECT
    cr.cr_item_sk AS item_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  GROUP BY cr.cr_item_sk
)
SELECT
  s.i_brand,
  s.i_item_id,
  s.i_item_desc,
  s.ca_zip,
  s.zip_prefix,
  s.brand_item_code,
  s.desc_number,
  s.total_sales,
  s.total_profit,
  s.sales_cnt,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  (s.total_profit - COALESCE(r.total_return_loss, 0)) AS adjusted_profit,
  ROW_NUMBER() OVER (ORDER BY (s.total_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.item_sk = r.item_sk
ORDER BY profit_rank
LIMIT 100
