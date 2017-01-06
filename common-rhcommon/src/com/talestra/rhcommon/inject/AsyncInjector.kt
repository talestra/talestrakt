package com.talestra.rhcommon.inject

import com.soywiz.korio.async.asyncFun

@Target(AnnotationTarget.CLASS)
annotation class Prototype

@Target(AnnotationTarget.CLASS)
annotation class Singleton

class AsyncInjector {
	private val instances = hashMapOf<Class<*>, Any?>()

	suspend inline fun <reified T : Any> get(): T = get(T::class.java)

	inline fun <reified T : Any> map(instance: T): AsyncInjector = map(T::class.java, instance)

	init {
		map<AsyncInjector>(this)
	}

	fun <T : Any?> map(clazz: Class<T>, instance: T): AsyncInjector {
		instances[clazz] = instance as Any
		return this
	}

	@Suppress("UNCHECKED_CAST")
	suspend fun <T : Any?> get(clazz: Class<T>): T = asyncFun {
		if (instances.containsKey(clazz) || clazz.getAnnotation(Singleton::class.java) != null) {
			if (!instances.containsKey(clazz)) {
				val instance = create(clazz)
				instances[clazz] = instance
			}
			instances[clazz]!! as T
		} else {
			create(clazz)
		}
	}

	@Suppress("UNCHECKED_CAST")
	suspend fun <T : Any?> create(clazz: Class<T>) = asyncFun {
		val constructor = clazz.declaredConstructors.first()
		val out = arrayListOf<Any>()
		for (paramType in constructor.parameterTypes) {
			out += get(paramType)
		}
		val instance = constructor.newInstance(*out.toTypedArray()) as T
		if (instance is AsyncDependency) {
			try {
				instance.init()
			} catch (e: Throwable) {
				println("AsyncInjector (${e.message}):")
				e.printStackTrace()
				throw e
			}
		}
		instance
	}
}

interface AsyncDependency {
	suspend fun init(): Unit
}