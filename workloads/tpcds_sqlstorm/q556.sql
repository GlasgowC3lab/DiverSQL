WITH base AS (
    SELECT
        d.d_date AS sale_date,
        i.i_category AS item_category,
        concat_ws(' :: ',
            concat('CC-', cc.cc_call_center_id),
            concat('CCName-', upper(cc.cc_name)),
            concat('CCHours-', replace(cc.cc_hours, ':', '-')),
            concat('ItemID-', regexp_replace(i.i_item_id, '[^A-Za-z0-9]', '')),
            concat('Product-', lower(i.i_product_name)),
            concat('DescLen-', CAST(length(i.i_item_desc) AS varchar)),
            concat('WordCnt-', CAST(cardinality(split(i.i_item_desc, ' ')) AS varchar)),
            concat('SecondWord-', element_at(split(i.i_item_desc, ' '), 2)),
            concat('FirstNum-', regexp_extract(i.i_item_desc, '[0-9]+')),
            concat('AlphaDesc-', regexp_replace(i.i_item_desc, '[^A-Za-z]', '')),
            concat('CustomerInit-', substring(upper(c.c_first_name), 1, 1), '.', substring(upper(c.c_last_name), 1, 1)),
            concat('EmailDomain-', lower(substring(c.c_email_address, strpos(c.c_email_address, '@') + 1))),
            concat('PromoName-', coalesce(p.p_promo_name, 'None')),
            concat('CPDesc-', trim(cp.cp_description)),
            concat('CPDept-', lower(cp.cp_department)),
            concat('Warehouse-', w.w_warehouse_name)
        ) AS complex_string,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_sales_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'WA'
      AND i.i_color IS NOT NULL
)
SELECT
    sale_date,
    item_category,
    complex_string,
    sum(cs_net_paid) AS total_net_paid,
    sum(cs_quantity) AS total_qty,
    avg(cs_sales_price) AS avg_sales_price
FROM base
GROUP BY sale_date, item_category, complex_string
ORDER BY total_net_paid DESC
LIMIT 200
