select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 967 and 967+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rosy' or i_color = 'lime') and 
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'linen') and
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'mint') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'cornflower') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'lace') and 
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'turquoise' or i_color = 'powder') and
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'sky') and
        (i_units = 'Pound' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'bisque') and
        (i_units = 'Dozen' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100
