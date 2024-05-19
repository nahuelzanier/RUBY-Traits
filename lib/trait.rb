class Trait

    def initialize(trait01:nil, trait02:nil, holder_module:nil, removed_methods:[])
        @trait01 = trait01
        @trait02 = trait02
        @redefined = nil
        @removed_methods = removed_methods
        if holder_module == nil
            @holder_module = self.class.get_aux_module
        else
            @holder_module = holder_module
        end
        @classes_applied = []
    end

    def self.from_block(&block)
        holder_module = get_aux_module
        holder_module.class_exec(&block)
        Trait.new(holder_module:holder_module)
    end

    def apply_to(a_class)
        if a_class.traits == nil
            a_class.instance_variable_set(:@traits, nil)
        end
        a_class.set_trait(self + a_class.traits)

        @classes_applied.push(a_class)

        apply_requirements(self, a_class)
        apply_methods(self, a_class)
    end

    #LOOKUP
    def lookup(trait, method_name, removed_methods)
        if trait == nil
            return []
        else
            removed_methods = removed_methods + trait.removed_methods
            if trait.redefined != nil and trait.redefined.has_method(method_name) and not trait.removed_methods.include?(method_name)
                [trait.redefined]
            else
                if trait.holder_module.instance_methods.include?(method_name) and not removed_methods.include?(method_name)
                    [trait] + lookup(trait.trait01, method_name, removed_methods) + lookup(trait.trait02, method_name, removed_methods)
                else
                    lookup(trait.trait01, method_name, removed_methods) + lookup(trait.trait02, method_name, removed_methods)
                end
            end
        end
    end

    #APPLY METHODS
    def apply_methods(trait, a_class)
        if trait != nil
            trait.apply_methods_to(a_class)
            trait.apply_methods(trait.trait01, a_class)
            trait.apply_methods(trait.trait02, a_class)
        end
    end

    def apply_methods_to(a_class)
        @holder_module.instance_methods(false).each do |method_name|
            unless a_class.instance_methods(false).include?(method_name)
                trait = self
                lookup_proc = Proc.new { |*args|
                    holder_traits = self.class.traits.lookup(self.class.traits, method_name, self.class.traits.removed_methods)
                    if holder_traits.length == 1
                        holder_traits[0].holder_module.instance_method(method_name).bind(self).call(*args)
                    else
                        if holder_traits.length == 0
                            raise NameError.new "#Trait exception# - No implementation for such method"
                        else
                            raise NameError.new "#Trait exception# - There's an unresolved conflict with the method"
                        end
                    end
                }
                a_class.define_method(method_name, lookup_proc)
            end
        end
    end

    #REQUIREMENTS
    def apply_requirements(trait, a_class)
        if trait != nil
            trait.add_required_methods(trait, a_class)
            trait.apply_requirements(trait.trait01, a_class)
            trait.apply_requirements(trait.trait02, a_class)
        end
    end

    def add_required_methods(trait, a_class)
        trait.required_methods.each do |method_name|
            unless a_class.instance_methods(true).include?(method_name)
                a_class.define_method(method_name) { raise NoMethodError.new '#Trait exception# - One of the required methods is not defined for the class' }
            end
        end
    end

    #COMPOSITION
    def composition(trait:self)
        if trait == nil
            return []
        else
            if trait.trait01 == nil and trait.trait02 == nil
                return [trait]
            else
                composition(trait:trait.trait01) + composition(trait:trait.trait02)
            end
        end
    end

    #OPERATIONS
    def +(trait)
        Trait.new(trait01:self, trait02:trait)
    end

    def -(method_name)
        removed = (self.removed_methods.clone).push(method_name)
        Trait.new(trait01:self, trait02:nil, removed_methods:removed)
    end

    #ALIAS
    def <<(alias_hash)  #alias_hash of {old_name: :new_name}
        already_a_method = false
        already_a_requirement = false
        alias_hash.values.each do |method_name|
            already_a_method = (already_a_method or has_method(method_name))
            already_a_requirement = (already_a_requirement or has_requirement(method_name))
        end
        if already_a_method
            raise NameError.new "#Trait exception# - One of the new method names is already being used"
        else
            if already_a_requirement
                raise NameError.new "#Trait exception# - One of the new method names matches that of a requirement"
            else
                new_trait = Trait.new(trait01:self)
                alias_hash.each do |original_name, new_name|
                    new_trait.holder_module.define_method(new_name, get_implementation(self, original_name))
                end
                new_trait
            end
        end
    end

    def get_implementation(trait, method_name)
        traits = lookup(trait, method_name, trait.removed_methods)
        if traits.length > 1
            raise NameError.new "#Trait exception# - There's an unresolved conflict with the method"
        else
            if traits.length == 0
                raise NameError.new "#Trait exception# - Unexpected error, method not found"
            else
                traits[0].holder_module.instance_method(method_name)
            end
        end
    end

    def has_method_rec(trait, method_name)
        if trait == nil
            return false
        else
            (trait.instance_methods.include?(method_name)) or has_method_rec(trait.trait01, method_name) or has_method_rec(trait.trait02, method_name)
        end
    end

    def has_requirement_rec(trait, method_name)
        if trait == nil
            return false
        else
            (trait.required_methods.include?(method_name)) or has_method_rec(trait.trait01, method_name) or has_method_rec(trait.trait02, method_name)
        end
    end

    #DEFINE METHOD
    def define_method(method_name, &block)
        if has_method(method_name)
            raise NameError.new "#Trait exception# - One of the new method names is already being used"
        else
            if has_requirement(method_name)
                raise NameError.new "#Trait exception# - One of the new method names matches that of a requirement"
            else
                @holder_module.define_method(method_name, block)
                @classes_applied.each do |a_class|
                    apply_methods_to(a_class)
                end
            end
        end
    end

    #CONFLICTS
    def redefine_method(method_name, &block)
        if @redefined == nil
            @redefined = Trait.new
        end
        conflicts = get_implementations(self, method_name)
        res_proc = Proc.new { |*args|
            conflicts.each do |method|
                block.call(method.bind(self), *args)
            end
        }

        @redefined.define_method(method_name, &res_proc)
    end

    #AUX
    def self.get_aux_module
        Module.new {
            @required = []

            def self.requires(*methods)
                @required.concat(methods)
            end

            def self.get_required_methods
                @required
            end
        }
    end

    #ACCESSORS
    def trait01
        @trait01
    end
    def trait02
        @trait02
    end
    def holder_module
        @holder_module
    end
    def instance_methods
        @holder_module.instance_methods
    end
    def instance_method(method_name)
        get_implementation(self, method_name)
    end
    def removed_methods
        @removed_methods
    end
    def required_methods
        @holder_module.get_required_methods
    end
    def has_method(method_name)
        has_method_rec(self, method_name)
    end
    def has_requirement(method_name)
        has_requirement_rec(self, method_name)
    end
    def redefined
        @redefined
    end
    def get_implementations(trait, method_name)
        traits = lookup(trait, method_name, trait.removed_methods)
        traits.map do |trait|
            trait.holder_module.instance_method(method_name)
        end
    end

end

class Class
    def uses(trait)
        trait.apply_to(self)
    end

    def has_trait(trait)
        @traits.composition.include?(trait)
    end

    def set_trait(trait)
        @traits = trait
    end

    def traits
        @traits
    end
end