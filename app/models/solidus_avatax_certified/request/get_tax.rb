# frozen_string_literal: true

module SolidusAvataxCertified
  module Request
    class GetTax < SolidusAvataxCertified::Request::Base
      def generate
        {
          createTransactionModel: {
            code: order.number,
            date: doc_date,
            discount: discount.to_s,
            commit: @commit,
            type: @doc_type || 'SalesOrder',
            lines: sales_lines
          }.merge(base_tax_hash)
        }
      end

      protected

      # Solidus 4.8 saves promotion adjustments together with the order after taxes,
      # so the persisted adjustments still hold the previous discount here.
      def discount
        promotion_discount = order.line_items.sum { |line_item| line_item_discount(line_item) } +
                             order.shipments.sum { |shipment| promotion_amount(shipment) } +
                             order.adjustments.promotion.eligible.sum(:amount)
        manual_discount = order.all_adjustments.where('amount < 0').where(source: nil).eligible.sum(:amount)

        (promotion_discount + manual_discount).abs
      end

      def line_item_discount(line_item)
        promotion_amount(line_item)
      end

      def promotion_amount(item)
        item.adjustments.select(&:promotion?).reject(&:marked_for_destruction?).sum(&:amount)
      end

      def doc_date
        order.completed? ? order.completed_at.strftime('%F') : Date.today.strftime('%F')
      end
    end
  end
end
