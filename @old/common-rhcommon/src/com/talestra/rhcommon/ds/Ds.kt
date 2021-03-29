package com.talestra.rhcommon.ds

import java.util.*

interface CollectionSize {
	val size: Int
}

class Queue<T> : CollectionSize, Iterable<T> {
	override fun iterator(): Iterator<T> = list.iterator()
	private val list = LinkedList<T>()
	fun queue(v: T) {
		list.addFirst(v)
	}

	fun dequeue(): T = list.removeLast()
	override val size: Int get() = list.size
}

class Stack<T> : CollectionSize, Iterable<T> {
	override fun iterator(): Iterator<T> = list.iterator()
	private val list = ArrayList<T>()
	fun push(v: T) {
		list.add(v)
	}

	fun pop(): T = list.removeAt(0)
	override val size: Int get() = list.size
}

fun CollectionSize.isEmpty() = this.size == 0
fun CollectionSize.isNotEmpty() = this.size != 0
