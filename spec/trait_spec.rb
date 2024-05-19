require 'rspec'
require 'trait'

describe '# trait #' do
    
    it 'a class with one trait knows wich trait it has applied' do
        a_trait = Trait.from_block do
        end

        a_class = Class.new do
            uses a_trait
        end

        expect(a_class.has_trait(a_trait)).to be true
    end

    it 'if you sum two traits a class can return a list of all it`s known traits' do
        trait01 = Trait.from_block do
        end
        trait02 = Trait.from_block do
        end

        a_class = Class.new do
            uses (trait01 + trait02)
        end

        expect(a_class.has_trait(trait01)).to be true
        expect(a_class.has_trait(trait02)).to be true
    end

    it 'if you apply more than one trait, the class includes them all' do
        trait01 = Trait.from_block do
        end
        trait02 = Trait.from_block do
        end
        trait03 = Trait.from_block do
        end

        a_class = Class.new do
            uses (trait01 + trait02 + trait03)
        end

        expect(a_class.has_trait(trait01)).to be true
        expect(a_class.has_trait(trait02)).to be true
        expect(a_class.has_trait(trait03)).to be true
    end

    it 'a class can call the methods from the applied trait as their own' do
        a_trait = Trait.from_block do
            def a_message
                'trait_message'
            end
        end

        a_class = Class.new do
            uses (a_trait)
        end
        an_instance = a_class.new
        
        expect(an_instance.a_message).to eq('trait_message')
    end

    it 'a class applied with a sum of traits and several traits knows all the methods from those traits' do
        trait01 = Trait.from_block do
            def message_01
                'trait01'
            end
        end
        trait02 = Trait.from_block do
            def message_02
                'trait02'
            end
        end
        trait03 = Trait.from_block do
            def message_03
                'trait03'
            end
        end

        a_class = Class.new do
            uses (trait01 + trait02 + trait03)
        end
        an_instance = a_class.new

        expect(an_instance.message_01).to eq('trait01')
        expect(an_instance.message_02).to eq('trait02')
        expect(an_instance.message_03).to eq('trait03')
    end

    it 'if two applied traits define the same method and the method is called it raises an exception' do
        trait01 = Trait.from_block do
            def message
                print('print a')
            end
        end
        trait02 = Trait.from_block do
            def message
                print('print b')
            end
        end

        a_class = Class.new do
            uses (trait01 + trait02)
        end
        an_instance = a_class.new

        expect {
            an_instance.message
        }.to raise_error(NameError, "#Trait exception# - There's an unresolved conflict with the method")
    end

    it 'you can remove a method from a specific trait' do
        trait01 = Trait.from_block do
            def message_01
                'm01'
            end
        end
        trait02 = Trait.from_block do
            def message_02
                'm02_of_trait02'
            end
        end
        trait03 = Trait.from_block do
            def message_02
                'm02_of_trait03'
            end
            def message_03
                'm03_of_trait03'
            end
        end
        trait04 = Trait.from_block do
            def message_03
                'm03_of_trait04'
            end
            def message_04
                'm04'
            end
        end
        trait05 = Trait.from_block do
            def message_03
                'm03_of_trait05'
            end
            def message_05
                'm05'
            end
        end

        a_class = Class.new do
            uses (trait01 + (trait02 - :message_02) + ((trait03 + trait04) - :message_03) + trait05)
        end
        an_instance = a_class.new

        expect(an_instance.message_01).to eq('m01')
        expect(an_instance.message_02).to eq('m02_of_trait03')
        expect(an_instance.message_03).to eq('m03_of_trait05')
        expect(an_instance.message_04).to eq('m04')
        expect(an_instance.message_05).to eq('m05')
    end

    it 'you can specify required methods for the recipient class,
     if the class doesn`t have them an exception is raised' do
        a_trait = Trait.from_block do
            requires :m01, :m02

            def message_01
                m01
            end
            def message_02
                m02
            end
        end

        a_class = Class.new do
            uses a_trait

            def m01
                return 'm01'
            end
        end
        an_instance = a_class.new

        expect(an_instance.message_01).to eq('m01')
        expect {
            an_instance.message_02
        }.to raise_error(NameError, '#Trait exception# - One of the required methods is not defined for the class')
    end

    it 'trying to create an alias for a method using an already existing method name raises an exception' do
        a_trait = Trait.from_block do
            def message_01
                'm01'
            end
            def message_02
                'm02'
            end
        end

        expect {
            a_trait << {message_01: :message_02}
        }.to raise_error(NameError, "#Trait exception# - One of the new method names is already being used")
    end

    it 'trying to create an alias using the name of a requirement raises an exception' do
        a_trait = Trait.from_block do
            requires :message01

            def message
                'message'
            end
        end

        expect {
            a_trait << {message: :message01}
        }.to raise_error(NameError, "#Trait exception# - One of the new method names matches that of a requirement")
    end

    it 'creating an alias for a method allows the message to be sent to instances the class the trait was applied' do
        a_trait = Trait.from_block do
            requires :m01

            def message_01
                m01
            end
        end

        a_class = Class.new do
            uses (a_trait << {message_01: :a_new_name})

            def m01
                'm01'
            end
        end
        an_instance = a_class.new

        expect(an_instance.a_new_name).to eq('m01')
    end

    it 'when a trait method is applied, self refers to the instance of the class' do
        trait01 = Trait.from_block do
            def message_01
                self
            end
        end
        trait02 = Trait.from_block do
            def message_02
                self
            end
        end
        trait03 = Trait.from_block do
            def message_02
                self
            end
            def message_03
                self
            end
        end
        trait04 = Trait.from_block do
            def message_03
                self
            end
            def message_04
                self
            end
        end
        trait05 = Trait.from_block do
            def message_03
                self
            end
            def message_05
                self
            end
        end

        a_class = Class.new do
            uses ((trait01 + ((trait02 << {message_02: :new_message_02}) - :message_02) + ((trait03 + trait04) - :message_03) + trait05) << {message_01: :new_message_01})
        end
        an_instance = a_class.new

        expect(an_instance.message_01).to eq(an_instance)
        expect(an_instance.new_message_02).to eq(an_instance)
        expect(an_instance.message_03).to eq(an_instance)
        expect(an_instance.message_04).to eq(an_instance)
        expect(an_instance.message_05).to eq(an_instance)
        expect(an_instance.new_message_01).to eq(an_instance)
    end

    it 'when a trait method with parameters is applied, the arguments are determined when the method is called' do
        trait01 = Trait.from_block do
            def message_01(value)
                value
            end
        end
        trait02 = Trait.from_block do
            def message_02(value)
                value
            end
        end
        trait03 = Trait.from_block do
            def message_02(value)
                value
            end
            def message_03(value)
                value
            end
        end
        trait04 = Trait.from_block do
            def message_03(value)
                value
            end
            def message_04(value)
                value
            end
        end
        trait05 = Trait.from_block do
            def message_03(value)
                value
            end
            def message_05(value)
                value
            end
        end

        a_class = Class.new do
            uses ((trait01 + ((trait02 << {message_02: :new_message_02}) - :message_02) + ((trait03 + trait04) - :message_03) + trait05) << {message_01: :new_message_01})
        end
        an_instance = a_class.new

        expect(an_instance.message_01(1)).to eq(1)
        expect(an_instance.new_message_02(2)).to eq(2)
        expect(an_instance.message_03(3)).to eq(3)
        expect(an_instance.message_04(4)).to eq(4)
        expect(an_instance.message_05(5)).to eq(5)
        expect(an_instance.new_message_01(6)).to eq(6)
    end

    it 'defining a new method allows any class previously applied to understand the message and use the method, unless the class already had the method defined' do
        a_trait = Trait.from_block do
            requires :required_method

            def trait_method
                'trait method01'
            end
        end

        another_trait = Trait.from_block do
            def new_method
                'another method01'
            end
        end

        class_01 = Class.new do
            uses a_trait

            def required_method
                self
            end
        end

        class_02 = Class.new do
            uses a_trait

            def required_method
                self
            end

            def class_method
                'class method01'
            end
        end

        class_03 = Class.new do
            uses (a_trait + another_trait)

            def required_method
                self
            end
        end

        instance_01 = class_01.new
        instance_02 = class_02.new
        instance_03 = class_03.new

        expect {
            another_trait.define_method(:new_method) { self }
        }.to raise_error(NameError, "#Trait exception# - One of the new method names is already being used")
        expect {
            a_trait.define_method(:required_method) { self }
        }.to raise_error(NameError, "#Trait exception# - One of the new method names matches that of a requirement")

        a_trait.define_method(:new_method) { self }

        expect(instance_01.new_method).to eq(instance_01)
        expect(instance_02.new_method).to eq(instance_02)
        expect {
            instance_03.new_method
        }.to raise_error(NameError, "#Trait exception# - There's an unresolved conflict with the method")
    end

    it 'you can resolve a conflict with the generic method redefine_method and a block' do
        array = []

        trait_01 = Trait.from_block do
            def message(array)
                array.push("trait01")
            end
        end
        trait_02 = Trait.from_block do
            def message(array)
                array.push("trait02")
            end
        end

        a_class = Class.new do
            uses (trait_01 + trait_02)
        end
        an_instance = a_class.new

        expect {
            an_instance.message
        }.to raise_error(NameError, "#Trait exception# - There's an unresolved conflict with the method")

        print((trait_01 + trait_02).get_implementations((trait_01 + trait_02), :message))

        a_class.traits.redefine_method(:message) { |method, *args|
                method.call(*args)
        }

        an_instance.message(array)

        expect(array).to eq(["trait01", "trait02"])
    end

end