WITH
  cs AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_net_profit,
      cp.cp_department,
      cp.cp_description,
      p.p_promo_name,
      ARRAY[
        p.p_channel_email,
        p.p_channel_catalog,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_press
      ] AS promo_channels
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND cp.cp_description LIKE '%fashion%'
  ),
  cr AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      r.r_reason_desc,
      d.d_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND regexp_like(r.r_reason_desc, '.*size.*')
  )
SELECT
  COALESCE(cs.cs_order_number, cr.cr_order_number) AS order_number,
  cs.cp_department,
  cs.cp_description,
  CONCAT(cs.cp_department, ': ', cs.cp_description) AS dept_desc,
  SUBSTRING(cs.cp_description FROM 1 FOR 10) AS short_desc,
  cs.p_promo_name,
  cr.r_reason_desc,
  CASE
    WHEN cs.cs_net_profit > 0 THEN 'Profitable'
    WHEN cs.cs_net_profit < 0 THEN 'Loss'
    ELSE 'Break-even'
  END AS profit_flag,
  pc.channel AS promo_channel,
  CASE WHEN pc.channel = 'Y' THEN 'Active' ELSE 'Inactive' END AS channel_status
FROM cs
FULL OUTER JOIN cr ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN LATERAL (
  SELECT channel
  FROM UNNEST(cs.promo_channels) AS t(channel)
) pc ON true
WHERE (
        cs.cp_description IS NOT NULL
        AND cs.cp_description LIKE '%summer%'
      )
   OR (
        cr.r_reason_desc IS NOT NULL
        AND cr.r_reason_desc LIKE '%size%'
      )
ORDER BY order_number
LIMIT 100
