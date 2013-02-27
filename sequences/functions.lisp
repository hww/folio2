;;;; ***********************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          functions.lisp
;;;; Project:       folio - the Bard runtime
;;;; Purpose:       functions that accept and produce
;;;;                sequences, series, generators, and streams
;;;; Author:        mikel evins
;;;; Copyright:     2013 by mikel evins
;;;;
;;;; ***********************************************************************

;;; ---------------------------------------------------------------------
;;; ABOUT
;;; ---------------------------------------------------------------------
;;; operations on sequences and sequence-like values. tables are treated
;;; as sequences of pairs. 
;;;
;;; functions that depend finite inputs are not defined on values such
;;; as series, which may be infinite in size. for example, LAST and
;;; LENGTH are not defined on series.
;;;
;;; tables are treated as sequences of pairs, except that functions
;;; that depend on a stable order are not defined on tables that do
;;; not define a stable order. for example, FIRST and ELEMENT are
;;; defined only on implementations of tables whose keys always appear
;;; in a stable order.

(in-package #:net.bardcode.folio.sequences)

;;; ---------------------------------------------------------------------
;;; utils
;;; ---------------------------------------------------------------------

(defmethod combined-type ((s1 null)(s2 null))
  (declare (ignore s1 s2))
  'list)

(defmethod combined-type ((s1 null) s2)
  (declare (ignore s1 s2))
  'list)

(defmethod combined-type ((s1 cons) s2)
  (declare (ignore s1 s2))
  'list)

(defmethod combined-type ((s1 string) (s2 string))
  (declare (ignore s1 s2))
  'string)

(defmethod combined-type ((s1 vector) (s2 vector))
  (declare (ignore s1 s2))
  'vector)

(defmethod combined-type ((s1 string) s2)
  (declare (ignore s1 s2))
  'vector)

(defmethod combined-type ((s1 seq) (s2 seq))
  (declare (ignore s1 s2))
  'seq)

(defmethod combined-type ((s1 seq) s2)
  (declare (ignore s1 s2))
  'list)

(defmethod combined-type ((s1 foundation-series)(s2 foundation-series))
  (declare (ignore s1 s2))
  'foundation-series)

(defmethod combined-type ((s1 foundation-series) s2)
  (declare (ignore s1 s2))
  'list)

(defmethod %split-at ((n integer)(ls null))
  (declare (ignore n ls))
  (values nil nil))

(defmethod %split-at ((n integer)(ls cons))
  (do ((i n)
       (collected nil)
       (remaining ls))
      ((or (null remaining)
           (<= i 0))
       (values (cl:reverse collected)
               remaining))
    (setf i (1- i)
          collected (cons (car remaining)
                          collected)
          remaining (cdr remaining))))


;;; ---------------------------------------------------------------------
;;; function add-first
;;; ---------------------------------------------------------------------
;;;
;;; (add-first x seq) => seq'
;;; ---------------------------------------------------------------------
;;; returns a new sequence that contains X prepended to the elements of
;;; SEQ

(defgeneric add-first (x seq))

(defmethod add-first (x (s null))(cons x s))
(defmethod add-first (x (s list))(cons x s))
(defmethod add-first (x (s vector))(concatenate 'vector (vector x) s))
(defmethod add-first (x (s string))(concatenate 'vector (vector x) s))
(defmethod add-first ((x character) (s string))(concatenate 'string (string x) s))
(defmethod add-first (x (s seq))(fset:with-first s x))
(defmethod add-first (x (s foundation-series))(series:catenate (series:scan (list x)) s))

;;; ---------------------------------------------------------------------
;;; function add-last
;;; ---------------------------------------------------------------------
;;;
;;; (add-last seq x) => seq'
;;; ---------------------------------------------------------------------
;;; returns a new sequence that contains X appended after the elements of
;;; SEQ

(defgeneric add-last (seq x))

(defmethod add-last ((s null) x)(cons x s))
(defmethod add-last ((s list) x)(append s (list x)))
(defmethod add-last ((s vector) x)(concatenate 'vector s (vector x)))
(defmethod add-last ((s string) x)(concatenate 'vector s (vector x)))
(defmethod add-last ((s string) (x character))(concatenate 'string s (string x)))
(defmethod add-last ((s seq) x)(fset:with-last s x))
(defmethod add-last ((s foundation-series) x)(series:catenate s (series:scan (list x))))

;;; ---------------------------------------------------------------------
;;; function any
;;; ---------------------------------------------------------------------
;;;
;;; (any seq) => anything
;;; ---------------------------------------------------------------------
;;; returns an arbitrary element of seq. any chooses the element
;;; randomly

(defgeneric any (seq))

(defmethod any ((s null)) (declare (ignore s)) nil)
(defmethod any ((s cl:sequence))(elt s (random (length s))))
(defmethod any ((s seq))(fset:@ s (random (fset:size s))))
(defmethod any ((s fset:map))(fset:@ s ()))

(defmethod any ((s foundation-series))
  (block searching
    (series:iterate ((x s))
        (when (zerop (random 2))
          (return-from searching x)))))


;;; function as
;;;
;;; (as type x) => an instance of type
;;; ---------------------------------------------------------------------

(defmethod as ((type (eql 'cl:list)) (val cl:list) )
  val)

(defmethod as ((type (eql 'cl:vector))(val cl:vector))
  val)

(defmethod as ((type (eql 'cl:string))(val cl:string))
  val)

(defmethod as ((type (eql 'seq))(val seq))
  val)

(defmethod as ((type (eql 'foundation-series))(val foundation-series))
  val)

;;; ---------------------------------------------------------------------
;;; function by
;;; ---------------------------------------------------------------------
;;;
;;; (by n seq) => seq'
;;; ---------------------------------------------------------------------
;;; returns a sequence of sequences constructed by taking the elements of
;;; SEQ N at a time

(defgeneric by (n seq))

(defmethod by (n (s null))
  (declare (ignore n))
  nil)

(defmethod by ((n integer)(s list))
  (assert (> n 0)() "count argument to BY must be greater than zero")
  (if (null s)
      nil
      (multiple-value-bind (collected remaining)(%split-at n s)
        (cons collected
              (by n remaining)))))

(defmethod by ((n integer)(s vector))
  (assert (> n 0)() "count argument to BY must be greater than zero")
  (multiple-value-bind (vcount leftover)(truncate (cl:length s) n)
    (let* ((last-seg (subseq s (* vcount n)))
           (tail (if (> (cl:length last-seg) 0)
                     (list last-seg)
                     nil))
           (segs (loop for i from vcount above 0 
                    do (push (subseq s (* (1- i) n)(* i n))
                             tail))))
      tail)))

(defmethod by ((n integer)(s seq))
  (assert (> n 0)() "count argument to BY must be greater than zero")
  (multiple-value-bind (vcount leftover)(truncate (fset:size s) n)
    (let* ((last-seg (fset:subseq s (* vcount n)))
           (tail (if (> (fset:size last-seg) 0)
                     (list last-seg)
                     nil))
           (segs (loop for i from vcount above 0 
                    do (push (fset:subseq s (* (1- i) n)(* i n))
                             tail))))
      tail)))

(defmethod by ((n integer)(s foundation-series))
  (assert (> n 0)() "count argument to BY must be greater than zero")
  (let* ((starts (series:scan-range :from 0 :by n))
         (ends (series:subseries starts 1))
         (chunks (series:map-fn t (lambda (x y)(series:subseries s x y)) starts ends)))
    chunks))

;;; ---------------------------------------------------------------------
;;; function coalesce
;;; ---------------------------------------------------------------------
;;;
;;; (coalesce fn &rest seqs) => seq'
;;; ---------------------------------------------------------------------
;;; coalesce combines N sequences into one. SEQs is a list of N sequences.
;;; FN is a function that accepts N inputs and returns one output. Applying
;;; coalesce yields a single sequence, series, generator, or stream
;;; that is the sequence of values produced by applying FN to SEQs.
;;; coalesce processes all the sequences in parallel, stopping when the
;;; end of one of them is reached. If the sequences are of different lengths
;;; then the remaining tails of longer sequences are ignored.

(defun coalesce (fn &rest seqs)
  (let ((seqs (mapcar 'scan seqs)))
    (series:collect (apply 'series:map-fn t fn seqs))))


;;; ---------------------------------------------------------------------
;;; function concat
;;; ---------------------------------------------------------------------
;;;
;;; (concat &rest seqs) => seq'
;;; ---------------------------------------------------------------------
;;; returns a new sequence. if SEQS is nil, then nil is returned. If
;;; seqs contains a single value then that value is returned. Otherwise,
;;; append returns (reduce 'append2 seqs)
;;; if you want to extend append with cases for additional sequence types,
;;; add methods to append2

(defun concat (&rest seqs)
  (if (null seqs)
      nil
      (if (null (cdr seqs))
          (cadr seqs)
          (reduce #'concat2 seqs))))

;;; ---------------------------------------------------------------------
;;; function concat2
;;; ---------------------------------------------------------------------
;;;
;;; (concat2 seq1 seq2) => seq3
;;; ---------------------------------------------------------------------
;;; returns a sequence containing all the elements of SEQ1 followed by
;;; all the elements of SEQ2.

(defgeneric concat2 (seq1 seq2))

(defmethod concat2 ((seq1 null)(seq2 null))(declare (ignore seq1 seq2)) nil)
(defmethod concat2 ((seq1 null)(seq2 cl:sequence))(declare (ignore seq1)) seq2)
(defmethod concat2 ((seq1 null)(seq2 seq))(declare (ignore seq1)) seq2)
(defmethod concat2 ((seq1 null)(seq2 foundation-series))(declare (ignore seq1)) seq2)

(defmethod concat2 ((seq1 cl:sequence)(seq2 null))(declare (ignore seq2)) seq1)
(defmethod concat2 ((seq1 cl:sequence)(seq2 cl:sequence)) (concatenate (combined-type seq1 seq2) seq1 seq2))
(defmethod concat2 ((seq1 cl:sequence)(seq2 seq))
  (concatenate (combined-type seq1 seq2) seq1 (fset:convert (combined-type seq1 seq2) seq2)))
(defmethod concat2 ((seq1 cl:sequence)(seq2 foundation-series))
  (series:catenate (series:scan seq1) seq2))

;;; ---------------------------------------------------------------------
;;; function drop
;;; ---------------------------------------------------------------------
;;;
;;; (drop n seq) => seq'
;;; ---------------------------------------------------------------------
;;; returns a new sequence containing the elements of SEQ after the first
;;; N elements have been removed

(defgeneric drop (n seq))

(defmethod drop ((n integer) (seq null))
  (error "index out of range: ~A" n))

(defmethod drop ((n integer) (seq cl:sequence))
  (subseq seq n))

(defmethod drop ((n integer) (seq seq))
  (fset:subseq seq n))

(defmethod drop ((n integer) (seq foundation-series))
  (series:subseries seq n))

;;; ---------------------------------------------------------------------
;;; function drop-while
;;; ---------------------------------------------------------------------
;;;
;;; (drop-while test seq) => seq'
;;; ---------------------------------------------------------------------

(defgeneric drop-while (test seq))

(defmethod drop-while (fn (seq null))
  (error "index out of range: ~A" n))

(defmethod drop-while (fn (seq cl:sequence))
  (let ((pos (cl:position-if-not fn seq)))
    (if pos
        (drop pos seq)
        nil)))

(defmethod drop-while (fn (seq seq))
  (let ((pos (fset:position-if-not fn seq)))
    (if pos
        (drop pos seq)
        nil)))

(defmethod drop-while (fn (seq foundation-series))
  (let* ((tests (series:map-fn t (cl:complement fn) seq))
         (flags (series:latch tests :post t)))
    (series:choose flags seq)))

;;; ---------------------------------------------------------------------
;;; function element
;;; ---------------------------------------------------------------------
;;;
;;; (element seq n) => 
;;; ---------------------------------------------------------------------
;;; returns the element of SEQ at index N

(defgeneric element (seq n))

(defmethod element ((s null) (n integer))
  (error "index out of range: ~A" n))

(defmethod element ((s cl:sequence) (n integer))
  (cl:elt s n))

(defmethod element ((s seq) (n integer))
  (fset:@ s n))

(defmethod element ((s foundation-series) (n integer))
  (series:collect-nth n s))

;;; ---------------------------------------------------------------------
;;; function empty?
;;; ---------------------------------------------------------------------
;;;
;;; (empty? seq) => a boolean
;;; ---------------------------------------------------------------------
;;; returns true if SEQ contains no elements, and false otherwise

(defgeneric empty? (seq))

(defmethod empty? ((s null))
  (declare (ignore s))
  t)

(defmethod empty? ((s cons))
  (declare (ignore s))
  nil)

(defmethod empty? ((s cl:sequence))
  (= 0 (cl:length s)))

(defmethod empty? ((s seq))
  (= 0 (fset:size s)))

(defmethod empty? ((s foundation-series))
  (= 0 (series:collect-length s)))

;;; ---------------------------------------------------------------------
;;; function every?
;;; ---------------------------------------------------------------------
;;;
;;; (every? test seq) => a boolean
;;; ---------------------------------------------------------------------
;;; returns true if SEQ contains no elements, and false otherwise

(defgeneric every? (test seq))

(defmethod every? (fn (s null))
  (declare (ignore fn s))
  t)

(defmethod every? (fn (s cl:sequence))
  (cl:every fn s))

(defmethod every? (fn (s seq))
  (fset::every fn s))

(defmethod every? (fn (s foundation-series))
  (series:collect-and (series:map-fn t fn s)))

;;; ---------------------------------------------------------------------
;;; function filter
;;; ---------------------------------------------------------------------
;;;
;;; (filter test seq) => seq'
;;; ---------------------------------------------------------------------
;;; returns those elements of SEQ for which TEST returns true

(defgeneric filter (test seq))

(defmethod filter (fn (s null))
  (declare (ignore fn s))
  nil)

(defmethod filter (fn (s cl:sequence))
  (cl:remove-if-not fn s))

(defmethod filter (fn (s seq))
  (fset::remove-if-not fn s))

(defmethod filter (fn (s foundation-series))
  (series:choose (series:map-fn t fn s) s))

;;; ---------------------------------------------------------------------
;;; function find
;;; ---------------------------------------------------------------------
;;;
;;; (find item seq &key from-end test test-not start end key) => anything
;;; ---------------------------------------------------------------------
;;; shadows cl:find, providing an extensible generic version

(defgeneric find (item seq &key from-end test test-not start end key &allow-other-keys))

(defmethod find (item (s cl:sequence) &key from-end test test-not start end key &allow-other-keys)
  (cl:find item s :from-end from-end :test test :test-not test-not
           :start start :end end :key key))

(defmethod find (item (s seq) &key test key &allow-other-keys)
  (fset::find s 0 :key key :test test))

(defmethod find (item (s foundation-series) &key test key &allow-other-keys)
  (series:collect-first (series:choose (series:map-fn t (or test 'equal) s)
                                        s)))

;;; ---------------------------------------------------------------------
;;; function first
;;; ---------------------------------------------------------------------
;;;
;;; (first seq) => anything
;;; ---------------------------------------------------------------------
;;; returns the first element of SEQ

(defgeneric first (seq))

(defmethod first ((s null))
  nil)

(defmethod first ((s cl:sequence))
  (cl:elt s 0))

(defmethod first ((s seq))
  (fset::@ s 0))

(defmethod first ((s foundation-series))
  (series:collect-first s))

;;; ---------------------------------------------------------------------
;;; function generate
;;; ---------------------------------------------------------------------
;;;
;;; (generate seq) => generator
;;; ---------------------------------------------------------------------
;;; returns a generator that returns one element at a time from the
;;; input SEQ

(defgeneric generate (seq))

(defmethod generate ((s cl:sequence))
  (series:generator (series:scan s)))

(defmethod generate ((s seq))
  (series:generator (fset:convert 'cl:vector s)))

(defmethod generate ((s foundation-series))
  (series:generator s))

;;; ---------------------------------------------------------------------
;;; function indexes
;;; ---------------------------------------------------------------------
;;;
;;; (indexes seq1) => seq2
;;; ---------------------------------------------------------------------
;;; returns a sequence of indexes to elements of SEQ1 

(defmethod indexes ((s null))
  (declare (ignore s))
  nil)

(defmethod indexes ((s cl:sequence))
  (series:collect 'cl:list
                  (indexes (scan s))))

(defmethod indexes ((s seq))
  (series:collect 'cl:list
                  (indexes (scan (fset:convert 'cl:vector s)))))

(defmethod indexes ((s foundation-series))
  (series:choose (series:positions (series:map-fn 'boolean (constantly t) (scan s)))))

;;; ---------------------------------------------------------------------
;;; function interleave
;;; ---------------------------------------------------------------------
;;;
;;; (interleave seq1 seq2) => seq3
;;; ---------------------------------------------------------------------
;;; returns a new sequence SEQ3 that interleaves the elements from
;;; SEQ1 and SEQ2. the first element of SEQ3 is the first element of SEQ1;
;;; the second element of SEQ3 is the first element of SEQ2; and 
;;; the elements of SEQ1 and SEQ2 continue to alternate. If SEQ1 and SEQ2
;;; are of unequal length then the elements of the longer past the 
;;; length of the shorter are appended after the last element of the
;;; shorter.

(defgeneric interleave (seq1 seq2))

(defmethod interleave ((s1 null)(s2 null))
  (declare (ignore s1 s2))
  nil)

(defmethod interleave ((s1 null)(s2 cl:sequence))
  (declare (ignore s1 s2))
  s2)

(defmethod interleave ((s1 null)(s2 seq))
  (declare (ignore s1 s2))
  s2)

(defmethod interleave ((s1 null)(s2 foundation-series))
  (declare (ignore s1 s2))
  s2)



(defmethod interleave ((s1 cl:sequence)(s2 null))
  (declare (ignore s1 s2))
  s1)


(defmethod interleave ((s1 cl:sequence)(s2 cl:sequence))
  (let* ((sr1 (series:scan s1))
         (sr2 (series:scan s2))
         (sr3 (interleave sr1 sr2))
         (out-type (combined-type s1 s2)))
    (series:collect out-type sr3)))

(defmethod interleave ((s1 cl:sequence)(s2 seq))
  (interleave s1 (fset:convert 'cl:list s2)))

(defmethod interleave ((s1 cl:sequence)(s2 foundation-series))
  (series:collect (combined-type s1 s2) 
    (interleave (series:scan s1) s2)))



(defmethod interleave ((s1 seq)(s2 null))
  (declare (ignore s1 s2))
  s1)

(defmethod interleave ((s1 seq)(s2 cl:sequence))
  (fset:convert 'seq (interleave (fset:convert 'cl:list s1) s2)))

(defmethod interleave ((s1 seq)(s2 seq))
  (fset:convert 'seq (interleave (fset:convert 'cl:list s1)
                                      (fset:convert 'cl:list s2))))

(defmethod interleave ((s1 seq)(s2 foundation-series))
  (fset:convert 'seq (interleave (fset:convert 'cl:list s1) s2)))



(defmethod interleave ((s1 foundation-series)(s2 null))
  (declare (ignore s1 s2))
  s1)

(defmethod interleave ((s1 foundation-series)(s2 cl:sequence))
  (interleave s1 (series:scan s2)))

(defmethod interleave ((s1 foundation-series)(s2 seq))
  (interleave s1 (fset:convert 'cl:list s2)))

(defmethod interleave ((s1 foundation-series)(s2 foundation-series))
  (let ((toggle t))
    (series:mingle s1 s2 
                   (lambda (x y) 
                     (setf toggle (not toggle))
                     toggle))))

;;; ---------------------------------------------------------------------
;;; function interpose
;;; ---------------------------------------------------------------------
;;;
;;; (interpose cupola seq1) => seq2
;;; ---------------------------------------------------------------------
;;; returns a new sequence SEQ2 that contains the elements of SEQ1, but
;;; with CUPOLA inserted between them

(defgeneric interpose (cupola seq))

(defmethod interpose (x (s null))
  (declare (ignore x s))
  nil)

(defmethod interpose (x (s cons))
  (if (null (cdr s))
      (list (car s))
      (cons (car s)
            (cons x
                  (interpose x (cdr s))))))

(defmethod interpose (x (s cl:vector))
  (let* ((outlen (1- (* 2 (cl:length s))))
         (outvec (make-array outlen :initial-element x)))
    (loop 
       for i from 0 below outlen
       for j from 0 below outlen by 2
       do (setf (elt outvec j) (elt s i)))
    outvec))

(defmethod interpose ((x cl:character) (s cl:string))
  (coerce (call-next-method) 'string))

(defmethod interpose (x (s seq))
  (interleave s (make-array (1- (fset:size s)) :initial-element x)))

(defmethod interpose (x (s foundation-series))
  (let* ((indexes (indexes s))
         (xs (series:choose (series:subseries indexes 1)(repeat x))))
    (interleave s xs)))

;;; ---------------------------------------------------------------------
;;; function join
;;; ---------------------------------------------------------------------
;;;
;;; (join cupola seqs) => seq
;;; ---------------------------------------------------------------------
;;; joins SEQS in the manner of join2, below. to add support for joining 
;;; new sequence types, add methods to join2

(defgeneric join (cupola seq))

(defmethod join (x (s null))
  (declare (ignore x s))
  nil)

(defmethod join (x (s cl:sequence))
  (cl:reduce (lambda (a b)(join2 x a b)) s))

(defmethod join (x (s seq))
  (fset:reduce (lambda (a b)(join2 x a b)) s))

(defmethod join (x (s foundation-series))
  (series:collect-fn t
                     (lambda () (series:collect-first s))
                     (lambda (a b) (join2 x a b))
                     (series:subseries s 1)))

;;; ---------------------------------------------------------------------
;;; function join2
;;; ---------------------------------------------------------------------
;;;
;;; (join cupola seq1 seq2) => seq3
;;; ---------------------------------------------------------------------
;;; concatenates SEQ1 and SEQ2 to form the new sequence SEQ3, with CUPOLA
;;; inserted between the elements of SEQ1 and SEQ2

(defgeneric join2 (cupola seq1 seq2))

(defmethod join2 (x (s1 cl:sequence)(s2 cl:sequence))
  (let* ((out-type (combined-type s1 s2))
         (cupola (coerce (list x) out-type)))
    (concatenate out-type s1 cupola s2)))

(defmethod join2 ((x character) (s1 cl:sequence)(s2 cl:sequence))
  (let* ((out-type (combined-type s1 s2))
         (cupola (string x)))
    (concatenate out-type s1 cupola s2)))

(defmethod join2 (x (s1 cl:sequence)(s2 seq))
  (let* ((out-type (combined-type s1 s2))
         (cupola (coerce (list x) out-type)))
    (concatenate out-type s1 cupola (fset:convert out-type s2))))

(defmethod join2 (x (s1 cl:sequence)(s2 foundation-series))
  (join2 x (series:scan s1) s2))


(defmethod join2 (x (s1 seq)(s2 cl:sequence))
  (let* ((out-type (combined-type s1 s2))
         (cupola (fset:convert out-type (list x))))
    (fset:concat out-type s1 cupola (fset:convert out-type s2))))

(defmethod join2 (x (s1 seq)(s2 seq))
  (let ((cupola (fset:convert 'seq (list x))))
    (fset:concat out-type s1 cupola s2)))

(defmethod join2 (x (s1 seq)(s2 foundation-series))
  (join2 x (series:scan (fset:convert 'cl:list s1)) s2))


(defmethod join2 (x (s1 foundation-series)(s2 cl:sequence))
  (join2 x s1 (series:scan s2)))

(defmethod join2 (x (s1 foundation-series)(s2 seq))
  (join2 x s1 (series:scan (fset:convert 'cl:list s2))))

(defmethod join2 (x (s1 foundation-series)(s2 foundation-series))
  (let ((cupola (series:scan (list x))))
    (series:catenate s1 cupola s2)))

;;; ---------------------------------------------------------------------
;;; function last
;;; ---------------------------------------------------------------------
;;;
;;; (last seq) => anything
;;; ---------------------------------------------------------------------
;;; returns the last element of SEQ

(defgeneric last (seq))

(defmethod last ((s null)) (declare (ignore s)) nil)
(defmethod last ((s cl:cons)) (cl:first (cl:last s)))
(defmethod last ((s cl:sequence))(cl:elt s (1- (cl:length s))))
(defmethod last ((s seq))(fset:last s))
(defmethod last ((s foundation-series))(series:collect-last s))

;;; ---------------------------------------------------------------------
;;; function length
;;; ---------------------------------------------------------------------
;;;
;;; (length seq) => an integer
;;; ---------------------------------------------------------------------
;;; returns a count of the elements in SEQ

(defgeneric length (seq))


(defmethod length ((s null)) (declare (ignore s)) 0)
(defmethod length ((s cl:sequence))(cl:length s))
(defmethod length ((s seq))(fset:size s))
(defmethod length ((s foundation-series))(series:collect-length s))

;;; ---------------------------------------------------------------------
;;; function image
;;; ---------------------------------------------------------------------
;;;
;;; (image fn seq) => seq'
;;; ---------------------------------------------------------------------
;;; returns a sequence containing the values produced by applying
;;; FN to each element of SEQ

(defgeneric image (fn seq))

(defmethod image  (fn (s null)) (declare (ignore s)) nil)
(defmethod image  (fn (s cl:sequence))(cl:map 'list fn s))
(defmethod image  (fn (s seq))(fset:image fn s))
(defmethod image  (fn (s foundation-series))(series:map-fn t fn s))

;;; ---------------------------------------------------------------------
;;; function make
;;; ---------------------------------------------------------------------
;;;
;;; (make 'cl:list &rest args) => args
;;; ---------------------------------------------------------------------
;;; create a list

(defmethod make ((type (eql 'cl:list)) &rest args &key &allow-other-keys)
  args)

(defmethod make ((type (eql 'cl:vector)) &key &allow-other-keys)
  )

(defmethod make ((type (eql 'cl:string)) &key &allow-other-keys)
  )

(defmethod make ((type (eql 'seq)) &key &allow-other-keys)
  )

(defmethod make ((type (eql 'foundation-series)) &key &allow-other-keys)
  )

(defmethod make ((type (eql 'sequence)) &key &allow-other-keys)
  )

(defmethod make ((type (eql 'series)) &key &allow-other-keys)
  )

;;; ---------------------------------------------------------------------
;;; function next-last
;;; ---------------------------------------------------------------------
;;;
;;; (next-last seq) => anything
;;; ---------------------------------------------------------------------
;;; returns the last-but-one element of seq

(defgeneric next-last (seq))

(defmethod next-last ((s null)) (declare (ignore s)) nil)

(defmethod next-last ((s cl:cons))
  (if (null (cdr s))
      nil
      (if (null (cddr s))
          (car s)
          (next-last (cdr s)))))

(defmethod next-last ((s cl:sequence))(cl:elt s (- (cl:length s) 2)))
(defmethod next-last ((s seq))(fset:@ s (- (fset:size s) 2)))
(defmethod next-last ((s foundation-series))(series:collect-nth (- (series:collect-length s) 2) s))

;;; ---------------------------------------------------------------------
;;; function partition
;;; ---------------------------------------------------------------------
;;;
;;; (partition seq &rest fn1 fn2 fn3...) => seq1 seq2 seq3...
;;; ---------------------------------------------------------------------
;;; returns a number of sequences equal to the number of FUNCTIONS.
;;; the elements of SEQ1 are produced by applying FN1 to each element of
;;; SEQ; the elements of SEQ2 are produced by applying FN2 to each 
;;; element of SEQ; and so on

(defgeneric partition (seq &rest fns))

(defmethod partition ((seq null) &rest fns)
  (declare (ignore seq fns))
  nil)

(defmethod partition ((seq cl:sequence) &rest fns)
  (apply #'values (cl:map 'cl:list
                          (lambda (fn)(cl:map (combined-type seq seq)
                                              fn seq))
                          fns)))

(defmethod partition ((seq seq) &rest fns)
  (apply #'values (cl:map 'cl:list
                          (lambda (fn)(fset:image fn seq))
                          fns)))

(defmethod partition ((seq foundation-series) &rest fns)
  (apply #'values (cl:map 'cl:list
                          (lambda (fn)(series:map-fn t fn seq))
                          fns)))

;;; ---------------------------------------------------------------------
;;; function position
;;; ---------------------------------------------------------------------
;;;
;;; (position item seq &key from-end test test-not start end key) => integer | nil
;;; ---------------------------------------------------------------------
;;; returns the index of ITEM in SEQ, or nil if it's not found

(defgeneric position (item sequence &key from-end test test-not start end key &allow-other-keys))

(defmethod position (item (seq null) &key from-end test test-not start end key &allow-other-keys)
  (declare (ignore item seq from-end test test-not start end key))
  nil)

(defmethod position (item (seq cl:sequence) &key from-end (test 'equal) test-not (start 0) end key &allow-other-keys)
  (cl:position item seq :from-end from-end :test test :test-not test-not :start start :end end :key key))

(defmethod position (item (seq seq) &key from-end test test-not start end key &allow-other-keys)
  (fset:position item seq :from-end from-end :test test :start start :end end :key key))

(defmethod position (item (seq foundation-series) &key test (start 0) end key &allow-other-keys)
  (let* ((key-fn (or key #'identity))
         (test-fn (or test 'equal))
         (test (lambda (x)(funcall test-fn (funcall key-fn item)(funcall key-fn x)))))
    (if end
        (let* ((s (series:subseries seq start end))
               (indexes (series:subseries (indexes seq) start end)))
          (series:collect-first (series:choose (series:map-fn t test s) indexes)))
        (let* ((s (series:subseries seq start))
               (indexes (series:subseries (indexes seq) start)))
          (series:collect-first (series:choose (series:map-fn t test s) indexes))))))

;;; ---------------------------------------------------------------------
;;; function position-if
;;; ---------------------------------------------------------------------
;;;
;;; (position-if seq &rest fn1 fn2 fn3...) => seq1 seq2 seq3...
;;; ---------------------------------------------------------------------
;;; returns a number of sequences equal to the number of FUNCTIONS.
;;; the elements of SEQ1 are produced by applying FN1 to each element of
;;; SEQ; the elements of SEQ2 are produced by applying FN2 to each 
;;; element of SEQ; and so on

(defgeneric position-if (test sequence &key from-end start end key &allow-other-keys))

(defmethod position-if (test (seq null) &key from-end start end key &allow-other-keys)
  (declare (ignore test seq from-end test test-not start end key))
  nil)

(defmethod position-if (test (seq cl:sequence) &key from-end (start 0) end key &allow-other-keys)
  (cl:position-if test seq :from-end from-end :start start :end end :key key))

(defmethod position-if (test (seq seq) &key from-end start end key &allow-other-keys)
  (fset:position-if test seq :from-end from-end :start start :end end :key key))

(defmethod position-if (test (seq foundation-series) &key (start 0) end key &allow-other-keys)
  (let* ((key-fn (or key #'identity))
         (test (lambda (x)(funcall test (funcall key-fn x)))))
    (if end
        (let* ((s (series:subseries seq start end))
               (indexes (series:subseries (indexes seq) start end)))
          (series:collect-first (series:choose (series:map-fn t test s) indexes)))
        (let* ((s (series:subseries seq start))
               (indexes (series:subseries (indexes seq) start)))
          (series:collect-first (series:choose (series:map-fn t test s) indexes))))))

;;; function range
;;;
;;; (range start end &key (by 1)) -> integer sequence
;;; ---------------------------------------------------------------------
;;; returns a list of integers starting with START and ending with
;;; (end - 1). Each succeeding integer differs from the previous one by BY.

(defun range (start end &key (by 1))
  (series:collect 'list (series:scan-range :from start :by by :below end)))

;;; function range-from
;;;
;;; (range-from start &key (by 1)) -> integer series
;;; ---------------------------------------------------------------------
;;; returns a series of integers starting with START and continuing
;;; forever. Each succeeding integer differs from the previous one by BY.

(defun range-from (n &key (by 1))
  (series:scan-range :from n :by by))

;;; function reduce
;;;
;;; (reduce fn &rest args) => 
;;; ---------------------------------------------------------------------
;;; applies FN to the first and second elements of ARGS, then applies it
;;; to the result and the third element of ARGS, and so on until the
;;; last element of ARGS is consumed. returns the last value produced.

(defmethod reduce (fn (seq null))
  (declare (ignore fn seq))
  nil)

(defmethod reduce (fn (seq cl:sequence))
  (cl:reduce fn seq))

(defmethod reduce (fn (seq seq))
  (fset:reduce fn seq))

(defmethod reduce (fn (seq foundation-series))
  (reduce fn (series:collect 'list seq)))


;;; function remove
;;;
;;; (remove item seq ) => cycling series
;;; ---------------------------------------------------------------------
;;; returns an infinitely-repeating sequence of VAL.

(defgeneric remove (test seq &key from-end test test-not start end count key &allow-other-keys))

(defmethod remove (item (s null) &key from-end test test-not start end count key &allow-other-keys)
  (declare (ignore item s))
  nil)

(defmethod remove (item (s cl:sequence) &key from-end (test 'equal) test-not (start 0) end count key &allow-other-keys)
  (cl:remove item s :from-end from-end :test test :test-not test-not :start start :end end :count count :key key))

(defmethod remove (item (s seq) &key test key &allow-other-keys)
  (fset:remove item s :test test :key key))

(defmethod remove (item (seq foundation-series) &key from-end test (start 0) end count key &allow-other-keys)
  (let* ((key-fn (or key 'identity))
         (test-fn (or test 'equal))
         (test (lambda (x)(funcall test-fn (funcall key-fn item)(funcall key-fn x)))))
    (if end
        (let* ((pre (series:subseries seq 0 start))
               (body (series:subseries seq start end))
               (post (series:subseries seq end))
               (tests (series:map-fn 'boolean (complement test) body))
               (result (series:choose tests body)))
          (series:catenate pre result post))
        (let* ((pre (series:subseries seq 0 start))
               (body (series:subseries seq start))
               (tests (series:map-fn 'boolean (complement test) body))
               (result (series:choose tests body)))
          (series:catenate pre result)))))

;;; function repeat
;;;
;;; (repeat val) => cycling series
;;; ---------------------------------------------------------------------
;;; returns an infinitely-repeating sequence of VAL.

(defun repeat (s)
  (series:scan-fn 't 
                  (lambda () s)
                  (lambda (i) s)))

;;; function rest
;;;
;;; (rest seq) => anything
;;; ---------------------------------------------------------------------
;;; returns all but the firt element of SEQ

(defgeneric rest (seq))

(defmethod rest ((s null))
  (declare (ignore s))
  nil)

(defmethod rest ((s cl:sequence))
  (cl:subseq s 1))

(defmethod rest ((s seq))
  (fset::less-first s))

(defmethod rest ((s foundation-series))
  (series:subseries s 1))

;;; function reverse
;;;
;;; (reverse SEQ) => seq'
;;; ---------------------------------------------------------------------
;;; returns the elements of SEQ in reverse order

(defgeneric reverse (seq))

(defmethod reverse ((s null))
  (declare (ignore s))
  nil)

(defmethod reverse ((s cl:sequence))
  (cl:reverse s))

(defmethod reverse ((s seq))
  (fset::reverse s))

(defmethod reverse ((s foundation-series))
  (series:scan (reverse (series:collect 'list s))))

;;; function scan
;;;
;;; (scan seq) => a series
;;; ---------------------------------------------------------------------
;;; returns a series equivalent to SEQ

(defgeneric scan (seq))

(defmethod scan ((s null)) (series:scan s))
(defmethod scan ((s cons)) (series:scan s))
(defmethod scan ((s vector)) (series:scan s))
(defmethod scan ((s seq)) (series:scan (fset:convert 'vector s)))
(defmethod scan ((s foundation-series)) s)

;;; function scan-map
;;;
;;; (scan-map fn seq) => a series
;;; ---------------------------------------------------------------------
;;; returns a series equivalent to (map FN SEQ)

(defgeneric scan-map (fn seq))

(defmethod scan-map (fn (s null)) (declare (ignore fn s)) nil)
(defmethod scan-map (fn (s cl:sequence)) (scan-map fn (scan s)))
(defmethod scan-map (fn (s seq)) (scan-map fn (scan s)))
(defmethod scan-map (fn (s foundation-series)) (series:map-fn t fn s))

;;; function second
;;;
;;; (second seq) => anything
;;; ---------------------------------------------------------------------
;;; returns the second element of SEQ

(defgeneric second (seq))

(defmethod second ((s null))
  nil)

(defmethod second ((s cl:sequence))
  (cl:elt s 1))

(defmethod second ((s seq))
  (fset::@ s 1))

(defmethod second ((s foundation-series))
  (series:collect-nth 1 s))

;;; ---------------------------------------------------------------------
;;; function select
;;; ---------------------------------------------------------------------
;;;
;;; (select seq1 indexes) => seq2
;;; ---------------------------------------------------------------------
;;; returns the elements of SEQ1 at the indexes given by the sequence
;;; INDEXES

(defgeneric select (seq indexes))

(defmethod select ((s null) indexes)
  (error "indexes out of range: ~A" indexes))

(defmethod select ((s cl:sequence) (indexes cl:sequence))
  (cl:map (combined-type s s)
          (lambda (i)(cl:elt s i))
          indexes))

(defmethod select ((s cl:sequence) (indexes seq))
  (fset:convert (combined-type s s)
                (fset:image (lambda (i)(cl:elt s i))
                            indexes)))

(defmethod select ((s cl:sequence) (indexes foundation-series))
  (series:collect (combined-type s s)
                  (series:map-fn t (lambda (i)(cl:elt s i))
                                 indexes)))


(defmethod select ((s seq) (indexes cl:sequence))
  (fset:convert 'seq
                (map 'cl:vector
                     (lambda (i)(cl:elt s i))
                     indexes)))

(defmethod select ((s seq) (indexes seq))
  (fset:image (lambda (i)(fset:@ s i))
              indexes))

(defmethod select ((s seq) (indexes foundation-series))
  (fset:convert 'seq
                (series:collect 'cl:vector
                                (series:map-fn t (lambda (i)(fset:@ s i))
                                               indexes))))


(defmethod select ((s foundation-series) (indexes cl:sequence))
  (series:choose (series:mask (series:scan indexes)) s))

(defmethod select ((s foundation-series) (indexes seq))
  (series:choose (series:mask (series:scan (fset:convert 'cl:vector indexes))) s))

(defmethod select ((s foundation-series) (indexes foundation-series))
  (series:choose (series:mask indexes) s))


;;; function shuffle
;;;
;;; (shuffle seq1) => seq2
;;; ---------------------------------------------------------------------
;;; returns a new sequence with the same elements as SEQ1, but
;;; in random order

(defgeneric shuffle (p))

(defmethod shuffle (s)
  (declare (ignore s))
  nil)

(defmethod shuffle ((s cl:sequence))
  (cl:sort (cl:copy-seq s) (lambda (x y)(zerop (random 2)))))

(defmethod shuffle ((s seq))
  (fset:sort s (lambda (x y)(zerop (random 2)))))

(defmethod shuffle ((s foundation-series))
  (shuffle (series:collect 'cl:list s)))

;;; function some?
;;;
;;; (some? test seq) => anything
;;; ---------------------------------------------------------------------
;;; returns the first element of SEQ for which TEST returns true, or
;;; nil otherwise

(defgeneric some? (test seq))

(defmethod some? (test (s null)) (declare (ignore fn s)) nil)
(defmethod some? (test (s cl:sequence)) (cl:some test s))

(defmethod some? (test (s seq)) 
  (let ((pos (fset:position-if test s)))
    (if pos
        (fset:@ s pos)
        nil)))

(defmethod some? (test (s foundation-series))
  (series:collect-first
   (series:choose 
    (series:map-fn t test s)
    s)))


;;; function split
;;;
;;; (split seq1 subseq) => seq2
;;; ---------------------------------------------------------------------
;;; returns a sequence of sequences. the output sequences are proper
;;; subsequences of SEQ1, obtained by splitting SEQ1 at occurrences
;;; of SUBSEQ. SUBSEQ does not appear in the output sequences. TEST,
;;; whose default value is equal, is used to match occurrences of
;;; SUBSEQ.

(defgeneric split (seq subseq &key test))

(defmethod split ((seq null) subseq &key test)
  (declare (ignore seq subseq test))
  nil)


(defmethod split ((seq cl:sequence) (subseq null) &key test)
  (declare (ignore seq subseq test))
  (cl:map 'cl:list
          (lambda (e)(coerce (list e) (combined-type seq seq)))
          seq))

(defmethod split ((seq cl:sequence) (subseq cl:sequence) &key (test 'equal))
  (let* ((pivot 0)
         (result '())
         (sublen (cl:length subseq))
         (ends (block scanning
                 (loop
                    (let* ((pos (search subseq seq :start2 pivot :test test)))
                      (if pos
                          (setf result (cons pos result)
                                pivot (+ pos sublen))
                          (return-from scanning result))))))
         (starts (cons 0 (mapcar (lambda (e)(+ e sublen))
                                 (reverse ends))))
         (ends (reverse (cons nil ends))))
    (cl:mapcar (lambda (s e)(cl:subseq seq s e)) starts ends)))

(defmethod split ((seq cl:sequence) (subseq seq) &key (test 'equal))
  (split seq (fset:convert 'cl:vector subseq) :test test))

(defmethod split ((seq cl:sequence) (subseq foundation-series) &key (test 'equal))
  (split seq (series:collect 'vector subseq) :test test))


(defmethod split ((seq seq) (subseq cl:sequence) &key (test 'equal))
  (fset:convert 'seq
                (split (fset:convert 'cl:vector seq)
                       subseq :test test)))

(defmethod split ((seq seq) (subseq seq) &key (test 'equal))
  (fset:convert 'seq
                (split (fset:convert 'cl:vector seq)
                       (fset:convert 'cl:vector subseq)
                       :test test)))

(defmethod split ((seq seq) (subseq foundation-series) &key (test 'equal))
  (fset:convert 'seq
                (split (fset:convert 'cl:vector seq)
                       (series:collect 'cl:vector subseq)
                       :test test)))


(defmethod split ((seq foundation-series) (subseq cl:sequence) &key (test 'equal))
  (series:scan (split (series:collect 'cl:vector seq)
                      subseq :test test)))

(defmethod split ((seq foundation-series) (subseq seq) &key (test 'equal))
  (series:scan (split (series:collect 'cl:vector seq)
                      (fset:convert 'cl:vector subseq) :test test)))

(defmethod split ((seq foundation-series) (subseq foundation-series) &key (test 'equal))
  (series:scan (split (series:collect 'cl:vector seq)
                      (series:collect 'cl:vector subseq) :test test)))


;;; ---------------------------------------------------------------------
;;; function subsequence
;;; ---------------------------------------------------------------------
;;;
;;; (subsequence seq start &optional end) => seq2
;;; ---------------------------------------------------------------------
;;; returns a new sequence containing the elements of SEQ starting with
;;; index START. If END is given, the last element of the new sequence is
;;; the element just before index END; otherwise, it is the last element
;;; of SEQ.

(defgeneric subsequence (seq start &optional end))

(defmethod subsequence ((s null) (start integer) &optional end)
  (error "Index out of range on NIL:" start))

(defmethod subsequence ((s cl:sequence) (start integer) &optional end)
  (cl:subseq s start end))

(defmethod subsequence ((s seq) (start integer) &optional end)
  (fset:subseq s start end))

(defmethod subsequence ((s foundation-series) (start integer) &optional end)
  (series::subseries s start end))

;;; function tails
;;;
;;; (tails seq) => seq'
;;; ---------------------------------------------------------------------
;;; returns a sequence of sequences beginning with SEQ, followed by
;;; the tail of SEQ, then the tail of the tail of SEQ, and so on,
;;; ending with the last non-empty tail

(defgeneric tails (seq))

(defmethod tails ((seq null))
  (declare (ignore fn s))
  nil)

(defmethod tails ((seq cons))
  (if (null (cdr seq))
      (list seq)
      (cons seq (tails (cdr seq)))))

(defmethod tails ((seq cl:sequence))
  (let ((indexes (range 0 (cl:length seq))))
    (mapcar (lambda (i)(cl:subseq seq i)) indexes)))

(defmethod tails ((seq foundation-series))
  (series:map-fn t
                 #'(lambda (i) (series:subseries seq i))
                 (indexes seq)))

;;; function take
;;;
;;; (take n seq) => seq'
;;; ---------------------------------------------------------------------
;;; returns a sequence containing the first N elements of SEQ

(defgeneric take (n seq))

(defmethod take ((n (eql 0))(s null))
  (declare (ignore n))
  nil)

(defmethod take ((n integer)(s null))
  (error "index out of range: ~s" n))

(defmethod take ((n integer)(s cl:sequence))
  (cl:subseq s 0 n))

(defmethod take ((n integer)(s seq))
  (fset::subseq s 0 n))

(defmethod take ((n integer)(s foundation-series))
  (series:subseries s 0 n))

;;; function take-by
;;;
;;; (take-by n advance seq) => a sequence of sequences
;;; ---------------------------------------------------------------------
;;; returns the elements of SEQ N at a time. each chunk beings ADVANCE
;;; places after the start of the previous chunk

(defgeneric take-by (n advance seq))

(defmethod take-by ((n (eql 0))(advance (eql 0))(s null))
  (declare (ignore n))
  nil)

(defmethod take-by ((n integer)(advance integer)(s null))
  (error "index and advance out of range: ~s, ~s" n advance))

(defmethod take-by ((n integer)(advance integer)(s cl:sequence))
  (let ((out-type (combined-type s s)))
    (cl:mapcar (lambda (p)(coerce (series:collect 'list p) out-type)) 
               (series:collect 'list (take-by n advance (series:scan s))))))

(defmethod take-by ((n integer)(advance integer)(s seq))
  (let ((out-type (combined-type s s)))
    (cl:mapcar (lambda (p)(coerce (series:collect 'list p) out-type)) 
               (series:collect 'cl:list
                 (take-by n advance
                          (series:scan (fset:convert 'vector s)))))))

(defmethod take-by ((n integer)(advance integer)(s foundation-series))
  (let ((indexes (indexes s)))
    (multiple-value-bind (is ps)
        (series:until-if #'null
                         indexes
                         (series:map-fn t
                                        (lambda (i)(series:subseries s i (+ i n)))
                                        indexes))
      ps)))


;;; function take-while
;;;
;;; (take-while test seq) => seq'
;;; ---------------------------------------------------------------------
;;; returns elements of SEQ one after the other until TEST returns true

(defgeneric take-while (test seq))

(defmethod take-while (test (s cl:sequence))
  (cl:subseq s 0 (cl:position-if test s)))

(defmethod take-while (test (s seq))
  (fset:subseq s 0 (fset:position-if test s)))

(defmethod take-while (test (s foundation-series))
  (multiple-value-bind (is ps)
      (series:until-if (lambda (x)(not (funcall test x)))
                       s
                       s)
    ps))


;;; function unique
;;;
;;; (unique seq &key (test 'equal)) => seq'
;;; ---------------------------------------------------------------------
;;; returns the elements of SEQ with duplicates removed. TEST is used
;;; to test whether two elements SEQ are the same.

(defgeneric unique (seq &key test))

(defmethod unique ((s cl:sequence) &key (test #'equal))
  (cl:remove-duplicates s :test test))

(defmethod unique ((s seq) &key (test #'equal))
  (fset:convert 'seq (cl:remove-duplicates (fset:convert 'list s) :test test)))

(defmethod unique ((seq foundation-series) &key (test #'equal))
  (series:choose
   (series:map-fn t
                  (lambda (e i)
                    (not
                     (some? (lambda (x)(funcall test e x)) 
                            (series:subseries seq 0 i))))
                  seq
                  (indexes seq))
   seq))


;;; function unzip
;;;
;;; (unzip seq) => seq1 seq2
;;; ---------------------------------------------------------------------
;;; SEQ must be a sequence of pairs. returns two sequences; the first
;;; contains the heads of the pairs in SEQ, and the second contains
;;; the tails

(defgeneric unzip (seq))

(defmethod unzip ((seq null))
  (declare (ignore seq))
  (values nil nil))

(defmethod unzip ((seq cons))
  (values (mapcar #'car seq)
          (mapcar #'cdr seq)))

(defmethod unzip ((seq seq))
  (values (fset:image #'car seq)
          (fset:image #'cdr seq)))

(defmethod unzip ((seq foundation-series))
  (values (series:map-fn t #'car seq)
          (series:map-fn t #'cdr seq)))

;;; function zip
;;;
;;; (unzip seq1 seq2) => seq3
;;; ---------------------------------------------------------------------
;;; returns a sequence of pairs in which each left element is from SEQ1
;;; and each right element is the corresponding one from SEQ2.

(defgeneric zip (seq1 seq2))

(defmethod zip ((seq1 null) seq2)
  (declare (ignore seq1 seq2))
  nil)

(defmethod zip (seq1 (seq2 null))
  (declare (ignore seq1 seq2))
  nil)


(defmethod zip ((seq1 cons)(seq2 cons))
  (mapcar #'cons seq1 seq2))

(defmethod zip ((seq1 cons)(seq2 cl:sequence))
  (zip seq1 (coerce seq2 'list)))

(defmethod zip ((seq1 cons)(seq2 seq))
  (zip (coerce seq1 'list) (fset:convert 'cl:list seq2)))

(defmethod zip ((seq1 cons)(seq2 foundation-series))
  (series:map-fn t #'cons (series:scan seq1) seq2))


(defmethod zip ((seq1 cl:sequence)(seq2 cons))
  (zip (coerce seq1 'list) seq2))

(defmethod zip ((seq1 cl:sequence)(seq2 cl:sequence))
  (zip (coerce seq1 'list) (coerce seq2 'list)))

(defmethod zip ((seq1 cl:sequence)(seq2 seq))
  (zip (coerce seq1 'list) (fset:convert 'cl:list seq2)))

(defmethod zip ((seq1 cl:sequence)(seq2 foundation-series))
  (series:map-fn t #'cons (series:scan seq1) seq2))


(defmethod zip ((seq1 seq)(seq2 cons))
  (zip (fset:convert 'cl:list seq1) seq2))

(defmethod zip ((seq1 seq)(seq2 cl:sequence))
  (zip (fset:convert 'cl:list seq1) (fset:convert 'cl:list seq2)))

(defmethod zip ((seq1 seq)(seq2 seq))
  (zip (fset:convert 'cl:list seq1) (fset:convert 'cl:list seq2)))

(defmethod zip ((seq1 seq)(seq2 foundation-series))
  (series:map-fn t #'cons (series:scan (fset:convert 'list seq1)) seq2))


(defmethod zip ((seq1 foundation-series)(seq2 cl:sequence))
  (series:map-fn t #'cons seq1 (series:scan seq2)))

(defmethod zip ((seq1 foundation-series)(seq2 seq))
  (series:map-fn t #'cons seq1 (series:scan (fset:convert 'list seq2))))

(defmethod zip ((seq1 foundation-series)(seq2 foundation-series))
  (series:map-fn t #'cons seq1 seq2))



