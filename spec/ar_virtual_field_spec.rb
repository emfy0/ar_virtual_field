# frozen_string_literal: true

describe ArVirtualField do
  model_with_table('Order') do
    table do |t|
      t.belongs_to :user
    end
    model do
      belongs_to :user
    end
  end

  model_with_table('User') do
    table do |t|
      t.string :name
      t.string :surname
    end

    model do
      has_many :orders

      virtual_field :fullname,
        select: 'name || surname',
        get: -> { "#{name}#{surname}" }

      virtual_field :total_orders,
        scope: -> { left_joins(:orders).group(:id) },
        select: "COUNT(orders.id)",
        get: -> { orders.count },
        default: 0
    end
  end

  before do
    user = User.create!(name: 'test', surname: 'testsur')
    other_user = User.create!

    Order.create!(user: user)
    Order.create!(user: other_user)
  end

  let(:user) { scope.first! }

  context 'when used without `:scope`' do
    context 'when queried without scope' do
      let(:scope) { User.all }

      it 'evaluated code in ruby' do
        expect(user[:fullname]).to eq nil
        expect(user.fullname).to eq "#{user.name}#{user.surname}"
      end
    end

    context 'when queried with scope' do
      let(:scope) { User.with_fullname }

      it 'evaluated code in database' do
        expect(user[:fullname]).to eq "#{user.name}#{user.surname}"
        expect(user.fullname).to eq "#{user.name}#{user.surname}"
      end

      it 'searches by virtual_field' do
        expect(scope.find_by!('fullname = ?', "#{user.name}#{user.surname}")).to eq user
      end
    end
  end

  context 'when used with `:scope`' do
    context 'when queried without scope' do
      let(:scope) { User.all }

      it 'evaluated code in ruby' do
        expect(user[:total_orders]).to eq nil
        expect(user.total_orders).to eq Order.where(user: user).count
      end
    end

    context 'when queried with scope' do
      let(:scope) { User.with_total_orders }

      it 'evaluated code in database' do
        total_orders = Order.where(user: user).count

        expect(user[:total_orders]).to eq total_orders
        expect(user.total_orders).to eq total_orders
      end

      it 'searches by virtual_field' do
        expect(scope.find_by!('total_orders = ?', Order.where(user: user).count)).to eq user
      end
    end
  end
end
