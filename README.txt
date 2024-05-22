Excerpts from | Traits: Composable Units of Behaviour⋆ by Nathanael Sch¨ arli, St´ ephane Ducasse, Oscar Nierstrasz, and Andrew P. Black |

 A trait is essentially a group of pure methods that serves as a building block for classes and is a primitive unit of code reuse. 
Traits have the following properties.
– A trait provides a set of methods that implement behaviour.
– A trait requires a set of methods that serve as parameters for the provided behaviour.
– Traits do not specify any state variables, and the methods provided by traits never access state variables directly.
 – Classes and traits can be composed from other traits, but the composition order is irrelevant. Conflicting methods must be explicitly resolved.
– Trait composition does not affect the semantics of a class: the meaning of the class is the same as it would be if all of the methods obtained from the trait(s) were defined directly in the class.
– Similarly, trait composition does not affect the semantics of a trait: a composite trait is equivalent to a flattened trait containing the same methods.

Problems with inheritance:
 o  Single Inheritance is the simplest inheritance model; it allows a class to inherit from at
 most one superclass. Although this model is well-accepted, it is not expressive enough
 to allow the programmer to factor out all the common features shared by classes in a
 complex hierarchy. Hence single inheritance sometimes forces code duplication.

  o Multiple Inheritance enables a class to inherit features from more than one parent class,
 thus providing the benefits of better code reuse and more flexible modeling. However,
 multiple inheritance uses the notion of a class in two competing roles: the generator of
 instances and the unit of code reuse. This gives rise to the following difficulties.

 	       - Conflicting features. With multiple inheritance, ambiguity can arise when conflicting
 	features are inherited along different paths. A particularly troublesome sit
	uation is the “diamond problem”  (also known as “fork-join inheritance”),
 	which occurs when a class inherits from the same base class via multiple
 	paths. Since classes are instance generators, they must all provide some minimal
 	common features (e.g., the methods =, hash, and asString), which are typically
	 inherited from a common root class such as Object. Thus, when several of these
	 classes are reused, the common features conflict.
	    There are two kinds of conflicting feature: methods and state variables. Whereas
	 method conflicts can be resolved relatively easily (e.g., by overriding), conflicting
 	state is more problematic. Even if the declarations are consistent, it is not clear
 	whether conflicting state should be inherited once or multiply.
 
     	 -Accessing overridden features. Since identically named features can be inherited from
 	different base classes, a single keyword (e.g., super) is not enough to access inher
	ited methods unambiguously. For example, C++ forces one to explicitly name
	 the superclass to access an overridden method; recent versions of Eiffel [29] suggest
 	the same technique1. This tangles class references with the source code, making the
	 code fragile with respect to changes in the architecture of the class hierarchy. Ex
	plicit class references are avoided in languages such as CLOS that impose a
 	linear order on the superclasses. However, such a linearization often leads to un
	expected behaviour and violates encapsulation, because it may change the
 	parent-child relationships among classes in the inheritance hierarchy.

    	- Factoring out generic wrappers. Multiple inheritance enables a class to reuse fea
	tures from multiple base classes, but it does not allow one to write a reusable entity
	 that “wraps” methods implemented in as-yet unknown classes. Assume that class A contains
 	methods read and write that provide unsynchronized access to some data. If it becomes
 	necessary to synchronize access, we can create a class SyncA that inherits from A and wraps
 	the methods read and write. That is, SyncA defines read and write methods that call
 	the inherited methods under control of a lock.
 	Now suppose that class A is part of a framework that also contains another class B
 	with read and write methods, and that we want to use the same technique to create a
	 synchronized version of B. Naturally, we would like to factor out the synchroniza
	tion code so that it can be reused in both SyncA and SyncB.
	 With multiple inheritance, the natural way to share code among different classes
 	is to inherit from a common superclass. This means that we should move the synchronization
 	code into a class SyncReadWrite that will become the superclass of
 	both SyncA and SyncB. Unfortunately this cannot work, because
	 super-sends are statically resolved. The super-sends in the read and write methods
	 of SyncReadWrite cannot possibly refer in one case to methods inherited from A
	 and in the other case to methods inherited from B.
 	It is possible to parameterize the methods in SyncReadWrite by using self sends of
 	abstract methods rather than explicit super sends. These abstract methods will be
 	implemented by the subclass. However, this still requires duplication
 	of methods in each subclass. Furthermore, avoiding name clashes between the syn
	chronized and unsynchronized versions of the read and write methods makes this
 	approach rather clumsy, and one has to make sure that the unsynchronized methods
 	are not publicly available in SyncA and SyncB.


 o  Mixin Inheritance.  A mixin is a subclass specification that may be applied to various
 parent classes in order to extend them with the same set of features. Mixins allow the
 programmer to achieve better code reuse than single inheritance while maintaining the
 simplicity of the inheritance operation. However, although inheritance works well for
 extending a class with a single orthogonal mixin, it does not work so well for composing 
a class from many mixins. The problem is that usually the mixins do not quite fit
 together, i.e., their features may conflict, and that inheritance is not expressive enough
 to resolve such conflicts. This problem manifests itself under various guises.

	-  Total ordering. Mixin composition is linear: all the mixins used by a class must be in
	herited one at a time. Mixins appearing later in the order override all the identically
 	named features of earlier mixins. When we wish to resolve conflicts by selecting
 	features from different mixins, we may find that a suitable total order does not exist.
 	 - Dispersal of glue code. With mixins, the composite entity is not in full control of the
 	way that the mixins are composed: the conflict resolution code must be hardwired
 	in the intermediate classes that are created when the mixins are used, one at a time.
 	Obtaining the desired combination of features may require modifying the mixins,
 	introducing new mixins, or, sometimes, using the same mixin twice.
 					... a class MyRectangle uses two mixins
	 MColor and MBorder that both provide a method asString. The implementations
 	of asString in the mixins first call the inherited implementation and then extend
	 the resulting string with information about their own state. When we compose the
 	two mixins to make the class MyRectangle, we can choose which of them should
	 come first, but we cannot specify how the different implementations of asString
 	are glued together. This is because the mixins must be added one at a time: in
 	Rectangle + MColor + MBorder we can access the behaviour of MBorder and the
 	mixed behaviour of Rectangle + MColor, but not the original behaviour of MColor
 	and Rectangle. Thus, if we want to adapt the way the implementations of asString
 	are composed (e.g., changing the separation character between the two strings), we
 	need to modify the involved mixins.
 	 - Fragile hierarchies. Because of linearity and the limited means for resolving conflicts,
 	the use of multiple mixins results in inheritance chains that are fragile with respect
 	to change. Adding a new method to one of the mixins may silently override an
 	identically named method of a mixin that appears earlier in the chain. Furthermore,
 	it may be impossible to reestablish the original behaviour of the composite without
 	adding or changing several mixins in the chain. This problem is especially critical
 	if one modifies a mixin that is used in many places across the class hierarchy.
 	As an illustration, suppose that in the previous example the mixin
	 MBorder does not initially define a method asString. This means that the imple
	mentation of asString in MyRectangle is the one specified by MColor. Now suppose 
	that the method asString is subsequently added to the mixin MBorder. Be
	cause of the total order, this new method overrides the implementation provided by
	 MColor. Worse, the original behaviour of the composite class MyRectangle cannot
	 be reestablished without changing several more mixins.

---------------------------------------------------------------------------------------------------------------

Syntax and utilities of Traits implemented by nahuelzanier


#create a trait you can do it using .from_block:
	
	a_trait = Trait.from_block do
	   def m01
		#method code
	   end
	end

#to add a trait to a class:
	a_class = Class.new do
	   uses a_trait	


#the class should be capable of using the methods defined in the trait
# you can add several traits to a class

	a_class  =  Class.new do
            	    uses (trait01 + trait02 + trait03)
        	end

# you can exclude a particular method from a trait, in this case the class will respond to
m01 but not to m02. The original a_trait can still be used intact on other classes.
	
	a_trait = Trait.from_block do
	   def m01
		#method code
	   end
	   def m02
		#method code
	   end
	end

	a_class  =  Class.new do
            	    uses  (a_trait - :m02)
        	end

# you can specify required methods for a trait, those should be present either from the class itself or another trait
        	a_trait = Trait.from_block do
            	   requires :m01, :m02

            	    def message_01
                	 m01
            	    end
            	    def message_02
                        m02
               	    end
      	 	 end


# you can specify an alias for a trait method

	a_trait << {old_name: :new_name}


# if you define a new method for a trait, all classes that has access to that trait will be able to respond to the message

	a_trait.define_method(:new_method) { self }

# if there's a conflict of methods in a trait composition you can use redefine_method, the code will be repeated for every
implementation of that particular method (it will call every implementation in this case)
	
	trait.redefine_method(:message) { |method, *args|
		method.call(*args)
	}


------------------------------------------------------------------------------------------------





