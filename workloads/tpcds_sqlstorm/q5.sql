WITH sales_string_metrics AS (
  SELECT
    cc.cc_call_center_id,
    cp.cp_department,
    sum(cs.cs_net_paid) AS total_net_paid,
    sum(
      length(cc.cc_name)
      + length(cc.cc_manager)
      + length(cc.cc_city)
      + length(cp.cp_description)
      + length(i.i_item_desc)
      + coalesce(length(p.p_promo_name), 0)
    ) AS total_concat_len,
    sum(
      length(
        regexp_replace(
          concat_ws(' ',
            cc.cc_name,
            cc.cc_manager,
            cc.cc_city,
            cp.cp_description,
            i.i_item_desc,
            coalesce(p.p_promo_name, '')
          ),
          '[^0-9]',
          ''
        )
      )
    ) AS total_digit_count,
    sum(
      length(
        regexp_replace(
          concat_ws(' ',
            cc.cc_name,
            cc.cc_manager,
            cc.cc_city,
            cp.cp_description,
            i.i_item_desc,
            coalesce(p.p_promo_name, '')
          ),
          '[^AEIOUaeiou]',
          ''
        )
      )
    ) AS total_vowel_count,
    sum(
      cardinality(
        split(
          concat_ws(' ',
            cc.cc_name,
            cc.cc_manager,
            cc.cc_city,
            cp.cp_description,
            i.i_item_desc,
            coalesce(p.p_promo_name, '')
          ),
          '\\s+'
        )
      )
    ) AS total_word_count,
    sum(
      length(
        regexp_replace(
          lower(
            concat_ws(' ',
              cc.cc_name,
              cc.cc_manager,
              cc.cc_city,
              cp.cp_description,
              i.i_item_desc,
              coalesce(p.p_promo_name, '')
            )
          ),
          '[^a-z]',
          ''
        )
      )
    ) AS total_alpha_lowercase_count
  FROM
    call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE
    cs.cs_net_paid IS NOT NULL
  GROUP BY
    cc.cc_call_center_id,
    cp.cp_department
)
SELECT
  cc_call_center_id,
  cp_department,
  total_net_paid,
  total_concat_len,
  total_digit_count,
  total_vowel_count,
  total_word_count,
  total_alpha_lowercase_count,
  round(1.0 * total_vowel_count / nullif(total_concat_len, 0), 3) AS vowel_ratio,
  round(1.0 * total_digit_count / nullif(total_concat_len, 0), 3) AS digit_ratio,
  round(1.0 * total_alpha_lowercase_count / nullif(total_concat_len, 0), 3) AS lowercase_alpha_ratio
FROM
  sales_string_metrics
ORDER BY
  total_net_paid DESC
LIMIT 100
